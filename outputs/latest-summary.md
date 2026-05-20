# Latest Result Summary

마지막 갱신: 2026-05-20

## 현재 Baseline

- Run ID: `otlite-gemma3-4b-hf-main`
- 날짜: 2026-05-15
- 모델: `google/gemma-3-4b-it`
- Backend: `hf`
- Task group: `open_telco_otlite`
- 점수: `acc=0.3718`
- 결과 파일:
  `results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.md`

## 해석

- 현재 가장 강한 영역은 `srsranbench`와 `teleqna`입니다.
- 가장 약한 영역은 `telemath`, `3gpp_tsg_gen`, `telelogs`입니다.
- Prompt truncation warning이 관찰되었으므로, generation-heavy 점수를 안정적인
  model-only 측정값으로 보기 전에 원인을 조사해야 합니다.
