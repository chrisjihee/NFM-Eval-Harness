# Start Here — Engineering / Provenance Repo

This repository (`NFM-Eval-Harness`) is **not** the recommended INL handoff entry point.
Use **`NFM-Eval-Harness-delivery`** for handoff, onboarding, the 30-minute smoke test,
and curated final results.

## Repository role
- Engineering source and development history
- Provenance: intermediate experiments, assistant work logs, diagnostic outputs, engineering notes

## Recommended reading order (for the owner)
1. `README.md`
2. `docs/engineering-repo-map.md`
3. `docs/archive-history-index.md`
4. `PROGRESS.md`
5. `EXPERIMENTS.md`
6. local `chat/` (assistant provenance; kept local/untracked — not onboarding docs)

## Current execution path
Recommended profiles remain `open_telco_otlite_gsma` / `open_telco_otfull_gsma`.
Diagnostic/legacy profiles: `*_lm_eval_baseline`, `*_mcgen`.
For curated final results, see the delivery repo (`results/final/`).

## Do not confuse
- `results/` and `outputs/` here may contain historical or intermediate runs.
- `chat/` is provenance, not onboarding documentation.
- The canonical handoff results live in the delivery repo under `results/final/`.
