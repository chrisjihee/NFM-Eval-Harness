# Release Notes

## v0.1-inl-delivery-2026-06-28 — INL delivery package

기준: `main` (PR #1~#5 merged, merge commit `7129050`). 지능네트워크연구실 전달용 패키지.
수치/결과 상세는 `outputs/overnight-otfull-results.md`, `FINAL_DELIVERY_SUMMARY.md`, `RESULTS_MANIFEST.md` 참조(여기서는 재기재하지 않음).

### Added
- GSMA 공개 scoring contract 정렬 profile: `open_telco_otlite_gsma` / `open_telco_otfull_gsma`(기본/권장) + MC sensitivity 진단 `*_mcgen`(비-default).
- 확장 후보 평가 산출물: `outputs/model-candidate-plan-extended.md`, `outputs/overnight-otfull-run-plan.md`, `outputs/overnight-otfull-results.md`, 모델별 `outputs/*-ot{lite,full}-gsma-delta.md`.
- 전달 문서: `INL_HANDOFF.md`, `RESULTS_MANIFEST.md`, `PACKAGING_CHECKLIST.md`, 본 `RELEASE_NOTES.md`.
- 전달 점검 자동화: `scripts/delivery_check.sh`, `scripts/check_tracked_file_sizes.py`, `make delivery-check`.

### Changed
- 기본 실행 경로를 `*_gsma`로 정리(PR #3). legacy는 `*_lm_eval_baseline`(diagnostic), bare `open_telco_otlite/otfull`은 fail-fast.
- 전달 문서 정리(PR #6 packaging): `FINAL_DELIVERY_SUMMARY.md` 기준을 `main`(PR #5)으로, `PROGRESS.md`/`outputs/latest-summary.md`의 "진행 중/미실행" 표현을 완료 milestone + 선택적 후속으로 재분류.
- 내부 dev 아티팩트(`chat/`, `lm-eval-ls-task`)와 진단 run(`results/smoke-*`, `conf-*`)을 전달 번들에서 제외(`.gitignore`; 로컬 유지).

### Validated
- **ot-full_gsma full split(16,866 docs) 14종 + reference**: leaderboard 11종이 public을 재현(비-gemma3 LB ±0.021 이내). non-LB 3종 internal 비교.
- tp=2(24~33B), FP8 MoE 동작 확인.
- `bash -n` / `make smoke` / `pytest tests/`(73 passed) / `make delivery-check` 통과.

### Known limitations
- 공식 GSMA stack 완전 재현 아님(MC engine 미정렬: 자유 generation vs 공식 제약 디코딩).
- gemma3 계열은 생성형 emission 취약으로 음의 delta 큼.
- reasoning/harmony·일부 멀티모달 모델은 단답 MC engine과 비호환(collapse=artifact).
- **license 미정(TBD)** — 외부 배포 전 결정 필요.

### Not included
- model weights / HF cache / per-sample dump / raw log(전부 비추적). 멀티모달·LMM·LAM, 동적 제어, Planning, RAG, Korean Telco QA(2차 과제 범위).

### Reproducibility
- 환경 핀: Python 3.12.13, torch 2.11.0+cu128, transformers 5.12.1, vllm 0.23.0, lm-eval pin `97a5e2c7`(상세 `ENVIRONMENT.md`).
- VM-induced 운영 레시피(NCCL loopback + offline HF cache 등)는 `INL_HANDOFF.md` §8 / `outputs/overnight-otfull-results.md` 참조.
