# Experiments

이 파일은 benchmark 실행을 짧게 정리하는 index입니다. Raw log나 큰 산출물은
넣지 않고, 필요하면 추적되는 summary 또는 local path만 연결합니다.

## Run Index

| Date | Run ID | Model | Backend | Tasks | Result | Notes |
|---|---|---|---|---|---:|---|
| 2026-05-15 | `otlite-gemma3-4b-hf-main` | `google/gemma-3-4b-it` | `hf` | `open_telco_otlite` | `0.3718 acc` | 첫 7-task `ot-lite` baseline. Generation task 점수가 낮고 truncation warning이 관찰됨. |

## 2026-05-15: Gemma 3 4B IT On ot-lite

- 명령:
  `MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh`
- 출력:
  `results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.md`
- Group score: `open_telco_otlite acc=0.3718`

Task별 점수:

| Task | `acc` | `acc_norm` |
|---|---:|---:|
| `open_telco_teleqna` | `0.4500` | `0.4490` |
| `open_telco_teletables` | `0.2000` | `0.2300` |
| `open_telco_oranbench` | `0.3667` | `0.5000` |
| `open_telco_srsranbench` | `0.5467` | `0.5467` |
| `open_telco_telemath` | `0.0100` | - |
| `open_telco_telelogs` | `0.1700` | - |
| `open_telco_3gpp_tsg_gen` | `0.0700` | - |

해석:

- 상대적으로 강한 영역은 `srsranbench`, `teleqna`입니다.
- 약한 영역은 `telemath`, `3gpp_tsg_gen`, `telelogs`입니다.
- 긴 prompt에서 left-truncation warning이 반복적으로 발생했으므로, 일부
  generation-heavy task 점수에는 context 손실 영향이 섞였을 수 있습니다.
