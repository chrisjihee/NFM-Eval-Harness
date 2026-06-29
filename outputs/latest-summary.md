# Latest Result Summary

> **Historical / engineering note:** This file belongs to the engineering/provenance repository.
> For the current INL handoff package and curated final results, use `NFM-Eval-Harness-delivery`.
> Some commit hashes, result paths, or operational notes may reflect the state at the time this file was written.
>
> **역사/개발 메모:** 이 파일은 engineering/provenance 저장소의 문서입니다. 현재 INL 전달 정본과 최종 curated 결과는 `NFM-Eval-Harness-delivery`를 기준으로 확인하세요. 본문 일부 commit hash·result path·운영 메모는 작성 당시 상태를 반영할 수 있습니다.

마지막 갱신: 2026-06-28

## 2026-06-28 PASS5 확장 후보 검증 (ot-lite 11 + ot-full 14, 가장 최신)

지능네트워크연구실 전달 전 확장 검증. 상세: `outputs/model-candidate-plan-extended.md`(ot-lite), `outputs/overnight-otfull-results.md`(ot-full), `outputs/overnight-otfull-run-plan.md`.

- **ot-full_gsma full split(16,866 docs) — LB 11종 + reference(gemma-3-4b) 전부 public 재현**: qwen2.5-32b 0.5050(−0.002,tp2)/falcon3-10b 0.4598(+0.001)/gemma2-9b 0.4352(+0.002)/qwen2.5-14b 0.4791(−0.006)/phi-4 0.4959(−0.009)/qwen2.5-7b 0.4460(−0.012)/nemo 0.4318(+0.014)/mistral-small-24b 0.4958(−0.021,tp2)/qwen3-8b 0.4479(+0.037). **비-gemma3 9종 ±0.021 이내.** gemma3 2종만 더 큼(gemma3-12b −0.037/gemma3-27b −0.047,tp2 — 생성형 emission 취약). non-LB internal: qwen3-30b-a3b-fp8 0.459/qwen3-14b 0.462/qwen3.5-9b 0.436.
- **tp=2 검증**(NCCL loopback fix), **환경(VM) 이슈 레시피**(standalone snapshot_download 선캐시+HF_HUB_OFFLINE=1+NCCL loopback+enforce_eager+MAXLEN8192+GMU0.9; Mistral=tokenizer_mode=mistral).
- **제외(artifact/비호환)**: gpt-oss-20b(harmony→MC collapse), gemma-4-E4B(토크나이저 비호환), Qwen3.6-27B-FP8(dl 실패), R1-Distill(collapse).

> **Rename 안내.** 권장/기본 실행 그룹은 `open_telco_otlite_gsma` /
> `open_telco_otfull_gsma`입니다(run 스크립트 기본값 — `TASKS` 생략 시 실행).
> legacy lm-eval baseline은 `open_telco_{otlite,otfull}_lm_eval_baseline`로 보존됩니다.
> bare `open_telco_otlite` / `open_telco_otfull`은 실행 불가입니다(fail-fast).
> 아래 과거 수치 중 bare 이름으로 기록된 것은 historical(rename 전 실행 사실)입니다.

## 2026-06-27 (delivery) 다중 모델 ot-lite_gsma 평가

지능네트워크연구실 전달용 6모델 `open_telco_otlite_gsma` full(unweighted task mean). 전체 분해는 `FINAL_DELIVERY_SUMMARY.md`.

| 모델 | uw | public | delta | 구분 |
|---|---:|---:|---:|---|
| Qwen2.5-7B-Instruct | 0.4544 | 0.4579 | −0.0035 | LB ✓근접 |
| Falcon3-10B-Instruct | 0.4791 | 0.4588 | +0.0203 | LB |
| gemma-3-12b-it | 0.4277 | 0.4638 | −0.0362 | LB (telemath 0.04 emission) |
| Qwen3-4B (think-OFF) | 0.4463 | — | — | 내부 (0/1700 `<think>`) |
| Qwen3-14B (think-OFF) | 0.4678 | — | — | 내부 (0/1700 `<think>`) |
| DeepSeek-R1-Distill-14B | 0.0514 | — | — | 내부 ⚠ MC collapse=artifact |

- leaderboard 3모델 delta 부호가 엇갈림(+0.020 / −0.004 / −0.036) → 억지 정렬 아님. MC 4종 engine 미정렬(자유 gen vs 제약 디코딩) caveat 유지.
- Qwen3 계열은 `enable_thinking=False`(opt-in `EXTRA_MODEL_ARGS`)로 추론 억제 검증(응답 `<think>` 0개). DeepSeek-R1-Distill은 해당 flag 무시 → MC max_gen_toks:8에 추론 산문 truncate → 붕괴(artifact, 능력치 아님).
- gemma-3-12b는 128K 기본 context가 40GB 단일카드 KV cache 초과 → `MAX_MODEL_LEN=8192`로 실행.
- compare: `outputs/{qwen2.5-7b,falcon3-10b,gemma3-12b}-otlite-gsma-delta.md` · 계획: `outputs/model-candidate-plan.md`.

## 2026-06-27 GSMA-aligned 프로파일 결과 (가장 중요)

scorer를 공식 `gsma-evals` 소스와 정렬한 비-default 그룹 `open_telco_otlite_gsma`(unweighted, 권장/기본)로 gemma-3-4b-it 실행:

- **unweighted 평균 `0.3992` ≈ public gemma3-4b `0.397` (delta +0.0022)**. 기존 ~−13.8%p 후보 격차의 거의 전부가 **scoring 방식(loglikelihood→generation) + 집계(sample-weighted→unweighted)** 로 설명됨.
- per-task delta 전부 ±0.04 내: teleqna 0.661/oran 0.673/srsran 0.780/teletables 0.250/telemath 0.100/telelogs 0.090(faithful)/3gpp 0.240.
- telelogs: raw GSMA contract에서 4B가 라벨 미출력 → faithful 0.090(collapse), `_gsma_hinted`(+1줄 형식 지시) `0.13` ≈ public 0.117. 격차는 prompt-format.
- **무결성**: "공식 재현" 주장 아님. MC engine(자유 gen vs 공식 제약 디코딩)이 최대 미정렬 축. 비교표 `outputs/gemma3-4b-otlite-gsma-delta.md`, contract `GSMA_SCORING_CONTRACT.md`.
- **ot-full_gsma (public 동일 split, 대규모 N) 완료**: unweighted `0.3926` ≈ public `0.397` (−0.0044). telelogs faithful `0.118` ≈ public `0.117`(대규모/1024budget에서 collapse 없음). 비교표 `outputs/gemma3-4b-otfull-gsma-delta.md`. → ot-lite·ot-full 양쪽에서 일관: ~−13.8%p 격차는 거의 전부 scoring+집계 차이.

## 2026-06-26 핵심 결과 (원인 격리)

1. **MC 격차의 지배적 원인 = scoring 방식.** 객관식을 generation 후 답 추출(`*_mcgen`, 비-default 실험)로
   바꾸면 점수가 public에 거의 일치 — gemma·Qwen **두 모델에서 재현**.
   - gemma: teleqna 0.451→**0.658**(pub 0.652), oranbench 0.373→**0.667**(pub 0.660), srsranbench 0.520→**0.780**(pub 0.740)
   - qwen: teleqna 0.532→**0.720**(pub 0.702), oranbench 0.380→**0.720**(pub 0.698), srsranbench 0.420→**0.820**(pub 0.777)
   - 공식 방식은 UNKNOWN이므로 `*_mcgen`는 **비-default 유지**(default scoring 동결, "공식 정렬" 주장 아님, scoring sensitivity 분석).
2. **생성형 저점수는 truncation 때문이 아님.** `MAX_LENGTH` 2048→8192로 truncation 0건이어도 점수 불변
   (telemath 0.01, 3gpp 0.06). 다음 가설: `max_gen_toks=48` + `until:["\n"]`가 CoT를 절단 → 다음 실험 권고.
3. **hf ↔ vllm parity OK** (MC |Δ|≤0.02).
4. **집계방식 정정**: local group acc는 sample-weighted, public는 unweighted. gemma 동일기준 0.255 vs 0.397 = −0.142.

## Legacy lm-eval Baseline (재현, 2026-06-26)

- 모델: `google/gemma-3-4b-it` | Backend: `hf` | Task group: `open_telco_otlite` (full) — historical pre-rename name; 현재 실행 이름은 `open_telco_otlite_lm_eval_baseline`.
- default group acc(sample-weighted): `0.370` / 7-task 단순평균: `0.255`
- `open_telco_otlite_mcgen`(비-default) group acc: `0.673`
- 결과: `results/otlite-gemma3-4b-hf-2/google__gemma-3-4b-it/`
- leaderboard 비교: `outputs/gemma3-4b-leaderboard-delta.md`

## 비교 모델

- `Qwen/Qwen2.5-7B-Instruct` | `hf` | `open_telco_otlite`: default group `0.423`(uw 0.286), mcgen group `0.732`
- 결과: `results/otlite-qwen2.5-7b-hf-1/`

## ot-full 최초 full run (public와 동일 split, 2026-06-26)

- Task group: `open_telco_otfull` — historical pre-rename name; 현재 실행 이름은 legacy `open_telco_otfull_lm_eval_baseline`(권장 기본은 `open_telco_otfull_gsma`).
- 모델: `google/gemma-3-4b-it` | Backend: `vllm`(tp=2) | 16,866 docs
- default unweighted **0.251** vs public **0.397** (delta −0.146); group(sample-weighted) 0.354
- **mcgen near-reproduction (대규모 N)**: teleqna 0.422→**0.630**(pub 0.652, N=10k), oranbench 0.353→**0.635**(pub 0.660), srsranbench 0.551→**0.777**(pub 0.740)
- teletables(default column) 낮음(표주입 경로 미설정); **`_gsma`/`_mcgen` teletables는 question-only=GSMA parity**. generation(telemath/3gpp) 여전히 낮음(별도 원인)
- 결과: `results/otfull-gemma3-4b-vllm-1/` · 비교: `outputs/gemma3-4b-otfull-leaderboard-delta.md`

## 남은 필수 blocker

- 없음. (PR #5 기준 `open_telco_otfull_gsma` full split 14종 평가 완료.)

## 선택적 후속 작업 (인수 후, 필요 시에만)

- 신규 모델 추가 시 `open_telco_otlite_gsma` smoke → `open_telco_otfull_gsma` 순서로 확장.
- reasoning/harmony 모델용 별도 non-GSMA diagnostic profile 설계.
- legacy/internal teletables superset가 필요할 때만 `TELETABLES_ROOT` 사용.
- generation-budget 실험으로 gemma 계열 telemath/telelogs emission 개선 탐색.
- (선택) `*_mcgen` 공식 추출 방식 확인 시 default 승격 재검토(별도 승인).
