# Engineering Repository Map

## Role split
- `NFM-Eval-Harness`: engineering / provenance repo (this repository)
- `NFM-Eval-Harness-delivery`: curated INL handoff repo (canonical for non-author users)

## Current runnable code
- `open_telco_lm_eval/tasks/**`
- `run_open_telco_otlite.sh`, `run_open_telco_otfull.sh`
- `scripts/compare_gsma_leaderboard.py`, `scripts/aggregate_repeats.py`
- `setup-pre.sh`, `setup-main.sh`, `setup-post.sh`

## Current recommended profiles
- `open_telco_otlite_gsma`, `open_telco_otfull_gsma`

## Diagnostic / legacy profiles
- `*_lm_eval_baseline`, `*_mcgen` (off the default path; bare `open_telco_otlite`/`otfull` fail-fast)

## Provenance / history (do not treat as onboarding docs)
- local `chat/**` (assistant work logs; untracked)
- older `outputs/**` and `results/**` (smoke / partial / legacy / intermediate runs)
- intermediate planning docs (`PLAN.md`, `HANDOFF.md`, `EXPERIMENTS.md`, `PROGRESS.md`, …)

## Generated output
- `outputs/**`: deltas, comparisons, candidate plans, summaries (mixed stages — see `outputs/README.md`)
- `results/**`: local run artifacts (mixed stages — see `results/README.md`)

## When to use which repo
Use **this** repo to: change task implementation, add profiles, debug lm-eval/vLLM, check historical decisions, preserve provenance.
Use the **delivery** repo to: hand off to INL, show final curated results, ask non-author users to run smoke tests.
