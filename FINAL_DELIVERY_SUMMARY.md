# FINAL DELIVERY SUMMARY — NFM-Eval-Harness

전달 대상: **지능네트워크연구실(Intelligent Network Lab)**
기준: `main` (PR #1~#5 merged, merge commit `7129050`) · 최종 갱신: 2026-06-28

이 문서는 NFM-Eval-Harness를 전달 가능한 최종 검증판으로 정리한 한 장짜리 요약이다.
- 인수자 빠른 시작: `INL_HANDOFF.md` · 전달 산출물 목록: `RESULTS_MANIFEST.md` · 전달 전 체크리스트: `PACKAGING_CHECKLIST.md` · 변경 이력: `RELEASE_NOTES.md`
- 최신 핵심 결과(PR #5, ot-full 14종 full-split): `outputs/overnight-otfull-results.md` (§4b 요약)
- 배경/상세: `HANDOFF.md`, `REPRODUCTION_NOTES.md`, `GSMA_SCORING_CONTRACT.md`, `TASK_MANIFEST.md`

> **정체성(필독).** 이 저장소는 EleutherAI **lm-evaluation-harness 기반 내부 NFM-LLM baseline harness**이다.
> 공식 GSMA leaderboard stack(Inspect AI 기반)의 완전 복제가 아니다. `_gsma` profile은
> **GSMA 공개 scoring contract에 정렬**된 비교용 profile이며, "공식 GSMA 완전 재현"을 주장하지 않는다.

---

## 1. 실행 방법 (Quick Start)

기본 실행 경로가 곧 GSMA-comparable profile이다(`TASKS` 생략 시 `*_gsma`).

```bash
# 환경 준비
./setup-pre.sh && ./setup-main.sh && ./setup-post.sh

# ot-lite_gsma full (기본값; 권장)
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh

# vLLM + ot-full_gsma
CONFIRM_FULL_RUN=1 BACKEND=vllm VLLM_VISIBLE_DEVICES=0 \
  MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh

# 결과 ↔ public leaderboard 비교
python scripts/compare_gsma_leaderboard.py --profile gsma --model gemma3-4b \
  --local-result <result.json> --out-md outputs/<key>-otlite-gsma-delta.md
```

- run 스크립트는 `--apply_chat_template` 항상 ON, `LIMIT=N`/`CONFIRM_FULL_RUN=1` 가드 내장.
- thinking 모델: `EXTRA_MODEL_ARGS=enable_thinking=False`(이번 pass 추가 opt-in passthrough), `LOG_SAMPLES=1`로 emission 검증.
- 대형(14B급): `BACKEND=vllm TENSOR_PARALLEL_SIZE=2 VLLM_VISIBLE_DEVICES=a,b`.

## 2. 기본 profile vs legacy 구분

| Profile | 이름 | 목적 | leaderboard 비교 |
|---|---|---|---|
| **기본/권장** | `open_telco_otlite_gsma` / `open_telco_otfull_gsma` | GSMA 공개 scoring contract 정렬 | Yes (unweighted task mean) |
| legacy | `open_telco_otlite_lm_eval_baseline` / `…otfull…` | 기존 lm-eval/loglikelihood baseline | No, diagnostic only |
| 진단 | `open_telco_*_mcgen` | MC scoring sensitivity 분석 | Partial, diagnostic only |

- bare `open_telco_otlite` / `open_telco_otfull`은 **실행 불가**(run 스크립트 fail-fast `exit 2`).
- 모든 비교는 **unweighted task mean vs public unweighted**로 통일한다(sample-weighted group acc 아님).

## 3. gemma-3-4b 기준 재현 (reference)

`_gsma` profile로 측정한 가장 중요한 결과(기존 PR#2, 이번 pass에서 재확인):

- **ot-lite_gsma unweighted `0.3992` ≈ public `0.397` (+0.0022)**.
- **ot-full_gsma(public 동일 split, 대규모 N) unweighted `0.3926` ≈ public `0.397` (−0.0044)**.
- 즉 과거 "~−13.8%p 후보 격차"의 거의 전부가 **scoring 방식(loglikelihood→generation) + 집계(sample-weighted→unweighted)** 로 설명된다(원인 단정 아님, caveat 유지).
- 상세: `outputs/gemma3-4b-otlite-gsma-delta.md`, `outputs/gemma3-4b-otfull-gsma-delta.md`.

## 4. 후보 모델 평가 결과 (ot-lite_gsma full, unweighted task mean)

| task | gemma3-4b* | qwen2.5-7b | falcon3-10b | gemma3-12b | qwen3-4b | qwen3-14b | r1-distill-14b |
|---|---:|---:|---:|---:|---:|---:|---:|
| teleqna | 0.661 | 0.721 | 0.737 | 0.727 | 0.674 | 0.741 | **0.000**⚠ |
| oranbench | 0.673 | 0.727 | 0.713 | 0.727 | 0.713 | 0.780 | **0.000**⚠ |
| srsranbench | 0.780 | 0.813 | 0.793 | 0.780 | 0.867 | 0.833 | **0.000**⚠ |
| teletables | 0.250 | 0.260 | 0.280 | 0.270 | 0.310 | 0.250 | **0.000**⚠ |
| telemath | 0.100 | 0.310 | 0.390 | 0.040‡ | 0.250 | 0.360 | 0.100 |
| telelogs | 0.090 | 0.140 | 0.160 | 0.150 | 0.060 | 0.000† | 0.050 |
| 3gpp_tsg | 0.240 | 0.210 | 0.280 | 0.300 | 0.250 | 0.310 | 0.210 |
| **unweighted** | **0.3992** | **0.4544** | **0.4791** | **0.4277** | **0.4463** | **0.4678** | **0.0514**⚠ |
| 구분 | ref | LB | LB | LB | int | int | int |

`*` gemma3-4b = historical PR#2 reference(`results/open_telco_otlite_gsma/`), 이번 pass 재실행 아님.
`⚠` r1-distill MC 붕괴 = artifact(§6). `†` qwen3-14b telelogs `\boxed{}` 미출력(emission 0.01, 산문 응답) → 알려진 telelogs 취약성.
`‡` gemma3-12b telemath 0.040 = `\boxed{}`/수치형식 emission 취약(gemma3-4b 0.100과 동일 축); MC 4종은 정상.

### 4a. leaderboard 3모델 (public delta)

| 모델 | local uw | public uw | delta |
|---|---:|---:|---:|
| Qwen2.5-7B-Instruct | 0.4544 | 0.4579 | **−0.0035** (근접) |
| Falcon3-10B-Instruct | 0.4791 | 0.4588 | **+0.0203** |
| gemma-3-12b-it | 0.4277 | 0.4638 | **−0.0362** |

- per-task delta 표: `outputs/qwen2.5-7b-otlite-gsma-delta.md`, `outputs/falcon3-10b-otlite-gsma-delta.md`, `outputs/gemma3-12b-otlite-gsma-delta.md`.
- MC 4종은 engine 미정렬(자유 single-letter generation vs 공식 제약 디코딩) → generation-vs-constrained **sensitivity**이지 공식 재현 아님. delta 부호는 모델마다 다르다(억지 정렬 아님).

### 4b. non-leaderboard 3모델 (내부 비교)

public row가 없어 reference(gemma3-4b 0.399 / qwen2.5-7b 0.454) 대비 상대 비교만 한다.

- **Qwen3-4B (thinking-OFF) 0.4463** — 동일 4B급 gemma3-4b(0.399) 대비 +0.047. MC 강함(srsran 0.867).
- **Qwen3-14B (thinking-OFF) 0.4678** — 후보 중 상위권(MC oran 0.780/teleqna 0.741). telelogs만 형식-emission으로 0.0.
- **DeepSeek-R1-Distill-14B 0.0514** — ⚠ MC 붕괴 artifact(§6), 능력치로 해석 금지.

## 4b. PASS5 확장 후보 평가 (ot-lite 11종 스크리닝 + ot-full 14종, 2026-06-27~28)

지능네트워크연구실 전달 전 확장 검증으로 10B/20B/30B leaderboard·non-leaderboard 후보를 대거 추가 평가했다. 상세 표는 `outputs/model-candidate-plan-extended.md`(ot-lite) / `outputs/overnight-otfull-run-plan.md` / `outputs/overnight-otfull-results.md`(ot-full) 참조.

- **ot-lite_gsma 스크리닝(신규 11종)**: LB 8종(phi-4 0.5225/qwen2.5-32b 0.503 tp2/mistral-small-24b 0.5013 tp2/qwen2.5-14b 0.489/qwen3-8b 0.4624/gemma3-27b 0.4563 tp2/gemma2-9b 0.4494/mistral-nemo 0.434) 전부 public 재현(Δ −0.048~+0.052); non-LB exotic 3종(qwen3.5-9b 0.446/qwen3-30b-a3b-fp8 0.475/ministral 0.35).
- **ot-full_gsma full split(14종)**: LB 11종 + reference(gemma-3-4b) **전부 public을 재현 — 9/11이 ±0.021, 핵심 결과**: qwen2.5-32b −0.002·falcon3-10b +0.001·gemma2-9b +0.002·qwen2.5-14b −0.006·phi-4 −0.009·qwen2.5-7b −0.012·nemo +0.014·mistral-small-24b −0.021. gemma3 계열만 −0.037~(생성형 emission 취약). non-LB(qwen3-30b-a3b-fp8 0.459/qwen3-14b 0.462/qwen3.5-9b 0.436)은 internal 비교.
- **tp=2 검증**: 24~32B 모델 NCCL loopback fix로 multi-GPU 정상(무hang).
- **제외(artifact/비호환, 능력치 아님)**: gpt-oss-20b(harmony 추론→단답 MC collapse), gemma-4-E4B(vLLM 토크나이저 비호환), Qwen3.6-27B-FP8(다운로드/로드 실패), R1-Distill(reasoning collapse).
- **환경 주의(이 호스트)**: 동일 노드 QEMU VM 가동 시 (1) NCCL 인터페이스 hang→`NCCL_SOCKET_IFNAME=lo NCCL_IB_DISABLE=1`, (2) vLLM in-process HF-hub 다운로드 hang→standalone `snapshot_download` 선캐시 후 `HF_HUB_OFFLINE=1`. 9B+ 모델은 `GPU_MEMORY_UTILIZATION=0.9`, Mistral은 `tokenizer_mode=mistral`.

## 5. thinking / reasoning 모델 처리

- `enable_thinking=False`(opt-in `EXTRA_MODEL_ARGS`)로 Qwen3 계열 추론 억제. **Qwen3-4B/14B 응답 1700개 중 `<think>` 0개** 확인. MC는 깨끗한 단일 letter.
- emission gate(LIMIT 검증) 통과: Qwen3 계열 MC letter / boxed emission 정상.

## 6. DeepSeek-R1-Distill collapse = artifact (능력치 아님)

- `enable_thinking=False`는 **Qwen3 전용 규약**이라 DeepSeek-R1-Distill 계열은 무시한다. 해당 chat template이 추론을 강제 시작시켜, MC(자유 generation, `max_gen_toks:8`) 응답이 잘린 추론 산문(`"Okay, so I have this question about"`)으로 truncate → 정답 letter 미도달 → MC 4종 ~0.
- 이는 **"always-reasoning 모델 × 단답 MC 엔진" 구조적 비호환**이다. budget이 큰 생성형 과목(telemath 1024 / 3gpp 256)은 부분 동작(0.10 / 0.21).
- 0.0514는 **engine-incompatibility artifact**로 명시하며, 진짜 후보 격차가 아니다. (향후: MC budget을 키운 별도 비-gsma 진단 task로 실제 능력 측정 가능 — 이번 범위 밖.)

## 7. TeleTables 사실 정정

- 공식 `gsma-evals/teletables.py`의 `record_to_sample`은 **question+choices만** 주입하고 표 본문은 넣지 않는다.
- 우리 `open_telco_teletables_mcgen`(`_gsma`)도 `doc_to_text_mc_gen` = question+choices만 → **공식과 parity**(저평가 아님).
- `TELETABLES_ROOT`/`_load_teletable_context`/`doc_to_text_teletables`는 **legacy `*_lm_eval_baseline` 전용**(GSMA보다 풍부한 superset)이다. → `_gsma` 결과를 "degraded due to missing tables"로 기술하지 않는다(그 표현은 legacy default-LL 컬럼에만 해당).

## 8. TeleMath 현황

- `telemath_gsma`/`full_telemath_gsma` YAML = `max_gen_toks:1024, until:[]`, scorer 공식 일치(isclose 0.01) → 정확.
- 문서(`GSMA_SCORING_CONTRACT.md` §2.5/§2.6/§3, `CLAUDE.md`)의 stale `max_gen_toks:256` 표기를 **per-task(telemath/telelogs 1024, 3gpp 256)** 로 정정 완료(근거: boxed-rate 256→0.00, 1024→0.80).

## 9. 한계 (정직한 분해)

- **engine 미정렬**: MC 4종은 자유 generation vs 공식 제약 디코딩 → 최대 미정렬 축. 공식 재현 아님.
- **stack 차이**: 공식 Inspect AI vs 우리 lm-eval. 동일 점수가 목표가 아니다.
- **variant/provider/revision parity 없음**: public row label만 일치, 가중치 revision·서빙 런타임 미보장.
- **집계**: 모든 비교는 unweighted task mean. sample-weighted group acc와 혼동 금지.
- **telelogs/3gpp emission 취약성**: `\boxed{}`/WG token 미출력 시 soft scorer가 INCORRECT 처리 → 일부 모델 저점수는 형식-emission artifact(지식 격차 아님).

## 10. 다음 단계 (인수 후 권장)

1. 6모델 ot-lite_gsma full 평가 완료(본 표/compare 확정). 신규 모델 ot-full_gsma 동일-split 직접비교는 후속 과제.
2. reasoning 모델용 별도 진단 task(MC budget↑) 도입 검토 — R1-Distill류 실제 능력 측정(비-gsma, 별도 승인).
3. `TELETABLES_ROOT` 확보 시 legacy teletables superset 재측정(선택).
4. NFM-LLM 후보 base 모델/도메인 적응 변형 투입 시 본 harness로 상대 비교(주 용도).

---

### 산출물 위치
- 모델별 delta: `outputs/{qwen2.5-7b,falcon3-10b,gemma3-12b}-otlite-gsma-delta.md`
- 후보 계획/메타데이터: `outputs/model-candidate-plan.md`
- 결과 raw: `results/otlite-gsma-<model>/`(curated `results_*.json`만 추적, samples는 .gitignore)
- run index: `outputs/run-index.jsonl` · 누적 요약: `outputs/latest-summary.md`
