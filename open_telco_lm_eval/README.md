# Open Telco ot-lite Tasks for NFM Evaluation Harness

This directory adds a small NFM-oriented starter harness on top of `lm-eval`.

## Included tasks

- `open_telco_teleqna`
- `open_telco_oranbench`
- `open_telco_srsranbench`
- `open_telco_3gpp_tsg`
- `open_telco_otlite` group task

These tasks use the public `GSMA/ot-lite` dataset and provide a practical MVP
for Open Telco baseline evaluation.

## Run

```bash
./run_open_telco_otlite.sh
```

Override the default model if needed:

```bash
MODEL_NAME=Qwen/Qwen2.5-1.5B-Instruct ./run_open_telco_otlite.sh
```

Run a subset:

```bash
TASKS=open_telco_teleqna,open_telco_oranbench ./run_open_telco_otlite.sh
```

## Notes

- `teleqna`, `oranbench`, `srsranbench`, and `3gpp_tsg` are implemented as
  `multiple_choice` tasks.
- `3gpp_tsg` uses a fixed 16-label working-group choice set so the score is
  based on label classification rather than free-form string matching.
- This is an MVP baseline harness, not a full reproduction of the official
  GSMA evaluation stack.
