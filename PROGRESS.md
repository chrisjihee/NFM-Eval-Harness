# Progress

마지막 갱신: 2026-06-26

## 현재 상태

- 이 저장소에는 GSMA `ot-lite`와 `ot-full`을 위한 LM-Evaluation-Harness task
  정의가 들어 있습니다.
- `open_telco_otlite`는 7개 benchmark `acc` 점수의 단순 평균을 사용하는 비교용
  task pack입니다.
- `open_telco_otfull`은 공개 Open Telco leaderboard의 7개 benchmark column을
  맞추는 방향으로 구성되어 있습니다.
- 실행 스크립트는 Hugging Face backend와 vLLM backend를 지원합니다.
- 이후 agent가 commit된 repo 파일만 보고도 문맥을 회복할 수 있도록 Codex
  Local/Cloud handoff 문서를 추가했습니다.

## 최근 Baseline

- 날짜: 2026-05-15
- 모델: `google/gemma-3-4b-it`
- Backend: Hugging Face
- Task group: `open_telco_otlite`
- 결과: `acc=0.3718`
- 결과 파일:
  `results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.md`

## 2026-06 패키징 pass (진행 중)

deep-interview → ralplan(consensus) → autopilot 흐름으로 진행. 계획:
`.omc/plans/nfm-eval-harness-consensus-plan.md`.

완료(GPU 불필요):
- Claude/GPT 중복 문서 6종을 한국어 중심 `CLAUDE.md`/`HANDOFF.md`/`FIRST_PROMPT.md`로
  통합하고 분리본은 `git rm`.
- **집계방식 정정**: local group acc `0.3718`은 sample-weighted(teleqna 1000샘플 지배),
  7-task 단순평균은 `0.259`. public `0.397`은 unweighted task mean →
  동일기준 실제 격차 약 `−13.8%p`(후보, 단정 아님). 최대 격차는 객관식 MC 3종.
- `scripts/smoke_test.sh` + `make smoke`(GPU 없이 task loading 검증) 추가 →
  18개 task(otlite/otlite_core4/otfull) 전부 로드 OK.
- `scripts/compare_gsma_leaderboard.py`(local↔`GSMA/leaderboard` delta, 가중/비가중 병기) 추가.
- `run_open_telco_*.sh`에 `LIMIT`/`CONFIRM_FULL_RUN` 가드 추가(가드 없는 full run 거부).
- 추적 문서의 raw `lm_eval` 실행 예시를 전부 `--limit`/가드 형태로 교체.
- `lm_eval`(pin `97a5e2c7`, `v0.4.12-12-g97a5e2c7`)를 `.venv`에 editable 설치
  (`--no-deps` + 보조 deps 6종, 하드핀 torch/vllm/transformers/datasets 불변 확인).
- Phase 0.5(attribution probe): `GSMA/leaderboard`에는 variant/extraction 컬럼이 없어
  public `gemma3-4b` variant pin 불가 → 재현 주장은 bounded 유지, `*_mcgen`는 비-default 동결.

## 다음 작업

- Phase 3: 객관식 MC의 generation-based 변형 `open_telco_*_mcgen`를 **비-default 실험 task**로 추가
  (leak-guard 적용, default scoring 동결), 생성형 truncation/parser 개선 + pytest.
- Phase 4(GPU, 단계 승인): Gemma3-4B ot-lite/ot-full 재실행, `hf`↔`vllm` parity,
  `Qwen/Qwen2.5-7B-Instruct` baseline, 수정 before/after 측정.
- generation-heavy task의 left-truncation(2902→2024 tokens) 완화 효과 측정.
- TeleTables 원본 표 데이터(`TELETABLES_ROOT`) 확보 시도.

## Handoff Notes

- Agent 작업 규칙의 시작점은 `AGENTS.md`입니다.
- 전체 log를 계획 문서에 붙여넣기보다 `EXPERIMENTS.md`에 실행 요약을 남깁니다.
- 최신 경량 결과 snapshot은 `outputs/latest-summary.md`에 유지합니다.
