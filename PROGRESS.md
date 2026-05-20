# Progress

마지막 갱신: 2026-05-20

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

## 다음 작업

- 전체 GPU benchmark 없이 task loading만 확인하는 작은 smoke-test 경로를
  추가합니다.
- `results/`에 raw JSON/Markdown 결과를 계속 git으로 추적할지, 앞으로는
  선별된 summary만 추적할지 결정합니다.
- 같은 모델에 대해 `hf`와 `vllm` backend 결과를 비교하고 run index에 남깁니다.
- generation-heavy `ot-lite` task에서 관찰된 prompt truncation warning을
  조사합니다.
- `telemath`, `telelogs`, `3gpp_tsg_gen` parser 안정성을 개선합니다.

## Handoff Notes

- Agent 작업 규칙의 시작점은 `AGENTS.md`입니다.
- 전체 log를 계획 문서에 붙여넣기보다 `EXPERIMENTS.md`에 실행 요약을 남깁니다.
- 최신 경량 결과 snapshot은 `outputs/latest-summary.md`에 유지합니다.
