# Archive / History Index

This file explains historical artifacts in the engineering repo. Nothing here is deleted —
historical documents are kept for provenance and annotated rather than removed.

## Milestones
- PR #1: packaging / guardrails / initial diagnosis (gap = aggregation artifact)
- PR #2: GSMA public scoring contract alignment (`*_gsma` profile)
- PR #3: naming cleanup and `_gsma` defaults (legacy `*_lm_eval_baseline`, bare-name fail-fast)
- PR #4: additional model validation + TeleTables/TeleMath cleanup
- PR #5: extended model screening + ot-full validation
- PR #6: delivery packaging (handoff docs / manifest / release notes / checklist)
- Post-PR#6: a separate curated handoff repo `NFM-Eval-Harness-delivery` was created
  with a fresh 10-model × 2-profile × 3-repeat rerun (`results/final/`).

## Historical logs
Local `chat/**` holds Claude Code / assistant work logs (untracked, provenance only).
Treat them as decision-trace material, not user-facing documentation.

## Historical results
`outputs/**` and `results/**` here may include smoke runs, partial/failed runs, legacy
baseline results, intermediate comparisons, and pre-delivery experiments.
For curated, repeated, final results use the delivery repo (`results/final/`).

## Stale-document policy
If a document is historical, add a short notice at the top (see the warning header on the
older handoff docs) rather than deleting it. Do not rewrite history unless the owner asks.
Numbers in historical docs are preserved as historical values and are not edited.
