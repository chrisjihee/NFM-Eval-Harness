# Start Here — Engineering / Provenance Repo

This repository (`NFM-Eval-Harness`) is the **engineering/provenance repository** —
development history, intermediate experiments, and diagnostic outputs live here.

> **INL handoff:** Use **`NFM-Eval-Harness-delivery`** as the canonical handoff package
> for onboarding, the smoke test, and curated final results.
> `HANDOFF_POINTER.md` and `INL_HANDOFF.md` have been removed; all handoff content
> now lives in `NFM-Eval-Harness-delivery`.

## Repository role
- Engineering source and development history
- Provenance: intermediate experiments, assistant work logs, diagnostic outputs, engineering notes

## Recommended reading order (for the owner)
1. `README.md`
2. `docs/engineering-repo-map.md`
3. `docs/archive-history-index.md`
4. `docs/PROGRESS.md`
5. `docs/EXPERIMENTS.md`
6. `docs/HANDOFF.md` — background context and known risks
7. local `chat/` (assistant provenance; kept local/untracked — not onboarding docs)

## Current execution path
Recommended profiles remain `open_telco_otlite_gsma` / `open_telco_otfull_gsma`.
Diagnostic/legacy profiles: `*_lm_eval_baseline`, `*_mcgen`.
For curated final results, see the delivery repo (`results/final/`).

## Do not confuse
- `results/` and `outputs/` here may contain historical or intermediate runs.
- `chat/` is provenance, not onboarding documentation.
- The canonical handoff results live in the delivery repo under `results/final/`.
