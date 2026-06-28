# INL_HANDOFF — 지능네트워크연구실 인수 가이드

기준: `main` (PR #1~#5 merged, `7129050`) · 2026-06-28.
이 문서는 **처음 인수하는 분**을 위한 시작점입니다. 30분이면 무엇인지·어떻게 돌리는지·결과가 무슨 의미인지 파악할 수 있습니다.

## 1. 이 레포가 무엇인가

ETRI Language Intelligence Lab의 **내부 NFM-LLM baseline harness**입니다. EleutherAI **lm-evaluation-harness 기반**으로 GSMA Open Telco AI 7개 통신 도메인 태스크를 실행합니다. 용도는 (1) NFM-LLM 후보 base 모델·도메인 적응 변형의 상대 비교, (2) GSMA 공개 leaderboard와 비교 가능한 신뢰도 확보입니다.

> **중요(필독):** 공식 GSMA stack(Inspect AI 기반)의 완전 복제가 **아닙니다**. `_gsma` profile은 **GSMA 공개 scoring contract에 정렬**된 비교용 profile입니다. 특히 MC는 자유 single-letter generation으로, 공식 제약 디코딩과 engine이 다릅니다(미정렬). 상세는 `REPRODUCTION_NOTES.md` / `GSMA_SCORING_CONTRACT.md`.

## 2. 설치

```bash
./setup-pre.sh && ./setup-main.sh && ./setup-post.sh   # GPU 서버
```
환경 핀/재설치 SOP는 `ENVIRONMENT.md`. lm-evaluation-harness pin sha `97a5e2c7`.

## 3. 가장 먼저 — smoke + acceptance (GPU 최소)

```bash
make smoke                                              # GPU 없이 task 로딩 검증
LIMIT=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh   # 1-sample 파이프라인
make delivery-check                                     # 전달 readiness(문서/secret/용량/tree)
```

## 4. 실제 실행 (ot-lite / ot-full)

```bash
# ot-lite_gsma (빠른 스크리닝; 기본값, TASKS 생략 가능)
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh

# ot-full_gsma (public 동일 split, 16,866 docs; vLLM 권장)
CONFIRM_FULL_RUN=1 BACKEND=vllm VLLM_VISIBLE_DEVICES=0 \
  MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```
- bare `open_telco_otlite`/`open_telco_otfull`은 **실행 불가**(fail-fast). legacy는 `*_lm_eval_baseline`(diagnostic).
- 대형 모델 운영 변수(tp=2, MAX_MODEL_LEN, GMU, enable_thinking, tokenizer_mode, HF_HUB_OFFLINE/NCCL)는 `README.md`의 "인수자 가이드" 표 참조.

## 5. 결과 비교

```bash
python scripts/compare_gsma_leaderboard.py --profile gsma --model <leaderboard_key> \
  --local-result <result_json> --out-md outputs/<key>-delta.md
```
비교 기준 = **7-task unweighted task mean** vs public unweighted.

## 6. 읽는 순서

1. `INL_HANDOFF.md`(이 문서) → 2. `FINAL_DELIVERY_SUMMARY.md`(한 장 요약) → 3. `outputs/overnight-otfull-results.md`(최신 핵심 결과) → 4. `RESULTS_MANIFEST.md`(산출물 위치) → 5. `REPRODUCTION_NOTES.md`/`GSMA_SCORING_CONTRACT.md`(caveat) → 6. `TASK_MANIFEST.md`(task 상세). 작업 규칙은 `AGENTS.md`/`CLAUDE.md`.

## 7. 주요 결과 (요약 — 수치는 출처 참조)

- ot-full_gsma full split에서 **leaderboard 모델 11종 + reference가 public을 재현**(비-gemma3 LB는 ±0.021 이내). gemma3 계열은 생성형 emission 취약으로 더 큰 음의 delta. non-LB는 internal 비교만.
- 정확한 수치/delta/제외 모델: `outputs/overnight-otfull-results.md`, 모델별 `outputs/*-otfull-gsma-delta.md`.

## 8. 운영 주의

- **HF token / gated models**: gemma·llama 등 gated 모델은 HF 약관 수락 + 토큰 필요. `HF_TOKEN` 환경변수(레포에 토큰 커밋 금지).
- **vLLM / CUDA forward-compat**: GPU 작업 전 `.venv` activate 필수(run 스크립트가 수행). vLLM 실패 시 `BACKEND=hf` fallback.
- **NCCL / offline cache (이 호스트 특이사항)**: 동일 노드에 VM이 떠 있으면 NCCL 인터페이스 자동탐지와 vLLM in-process HF-hub 다운로드가 hang할 수 있음 → standalone `huggingface_hub.snapshot_download` 선캐시 후 `HF_HUB_OFFLINE=1` + `NCCL_SOCKET_IFNAME=lo NCCL_IB_DISABLE=1`. 강제종료 후 stale `~/.cache/huggingface/**/*.lock` 삭제. 상세는 `outputs/overnight-otfull-results.md` 운영 메모.
- **데이터셋**: 로컬 캐시 없으면 첫 run에서 다운로드.

## 9. Known caveats

- "공식 GSMA 완전 재현" 주장 아님(engine 미정렬 — MC 자유 gen vs 공식 제약 디코딩).
- reasoning/harmony 모델(gpt-oss, R1-Distill 등)·일부 멀티모달은 단답 MC engine과 비호환 → MC collapse는 **artifact**(능력치 아님).
- gemma3 계열 telemath/telelogs는 `\boxed{}` emission 취약 → 생성형 점수 저평가 경향.
- license: **미정(TBD)**. 외부 배포 전 GSMA dataset/lm-eval/vLLM/model license와 별개로 결정 필요(`PACKAGING_CHECKLIST.md`).

## 10. 인수 체크리스트

- [ ] `make smoke` / `LIMIT=1` acceptance / `make delivery-check` 통과 확인.
- [ ] `FINAL_DELIVERY_SUMMARY.md` + `outputs/overnight-otfull-results.md` 결과 검토.
- [ ] HF token·gated 모델 접근 설정.
- [ ] 외부 배포 여부에 따른 license 결정.
- [ ] (선택) 신규 모델은 ot-lite smoke → ot-full 순서로 확장(`PROGRESS.md` 선택적 후속).
