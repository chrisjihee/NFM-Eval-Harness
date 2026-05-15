# Open Telco Tasks for NFM Evaluation Harness

This directory adds NFM-oriented Open Telco tasks on top of `lm-eval`.

## Included tasks

### `ot-lite` packs

- `open_telco_teleqna`
- `open_telco_teletables`
- `open_telco_oranbench`
- `open_telco_srsranbench`
- `open_telco_3gpp_tsg`
- `open_telco_3gpp_tsg_gen`
- `open_telco_telemath`
- `open_telco_telelogs`
- `open_telco_otlite` group task
- `open_telco_otlite_core4` legacy group task

These tasks use the public `GSMA/ot-lite` dataset. `open_telco_otlite` is now a
7-task leaderboard-style comparison pack, while `open_telco_otlite_core4`
preserves the original 4-task starter bundle.

### `ot-full` leaderboard-oriented pack

- `open_telco_full_teleqna`
- `open_telco_full_teletables`
- `open_telco_full_oranbench`
- `open_telco_full_srsranbench`
- `open_telco_full_telemath`
- `open_telco_full_telelogs`
- `open_telco_full_3gpp_tsg`
- `open_telco_otfull` group task

These tasks use the public `GSMA/ot-full` dataset and mirror the 7 benchmark
columns exposed by the public `Open Telco AI Leaderboard`.

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

Run the legacy 4-task starter pack:

```bash
TASKS=open_telco_otlite_core4 ./run_open_telco_otlite.sh
```

Run the 7-task `ot-full` pack:

```bash
./run_open_telco_otfull.sh
```

Override the backend or model if needed:

```bash
BACKEND=vllm VLLM_VISIBLE_DEVICES=3 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

## Notes

- `open_telco_otlite` now uses an unweighted mean of the 7 benchmark `acc`
  scores so it can be compared more directly with `open_telco_otfull` and the
  public leaderboard average.
- `open_telco_otlite_core4` preserves the previous 4-task setup, including the
  multiple-choice version of `3gpp_tsg`.
- `open_telco_3gpp_tsg` is still the original multiple-choice convenience task.
- `open_telco_3gpp_tsg_gen`, `open_telco_telemath`, and `open_telco_telelogs`
  use generation plus custom answer parsing.
- This is an MVP baseline harness, not a full reproduction of the official
  GSMA evaluation stack.
- `open_telco_otfull` uses an unweighted mean of the 7 benchmark `acc` scores
  to align with the public leaderboard average calculation.
- `open_telco_full_3gpp_tsg`, `open_telco_full_telemath`, and
  `open_telco_full_telelogs` use generation plus custom answer parsing rather
  than raw string exact-match.
- `open_telco_full_teletables` works with the public `GSMA/ot-full` rows out of
  the box, and can inject original table content automatically when
  `TELETABLES_ROOT` points to the extracted `tables/<document_id>/<table_id>/`
  tree from the upstream `netop/TeleTables` release.
