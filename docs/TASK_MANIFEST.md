# Task manifest: Open Telco tasks in NFM-Eval-Harness

Last updated: 2026-06-27

This manifest describes the current LM-Evaluation-Harness task packs implemented in this repository.

## Naming policy (read first)

Task/group names follow a single consistent convention:

- **Default / recommended GSMA-compatible**: `open_telco_otlite_gsma` /
  `open_telco_otfull_gsma` (the run-script defaults). These are the only
  leaderboard-comparable groups. Their members are the additive `*_mcgen` (MC) and
  `*_gsma` (generation) tasks.
- **Legacy lm-eval baseline (preserved, NOT deleted)**: every former bare group and
  task now carries an `_lm_eval_baseline` postfix and is **diagnostic only — do not
  compare against the public leaderboard**. Examples: `open_telco_otlite` →
  `open_telco_otlite_lm_eval_baseline`, `open_telco_otfull` →
  `open_telco_otfull_lm_eval_baseline`, `open_telco_otlite_core4` →
  `open_telco_otlite_core4_lm_eval_baseline`, `open_telco_teleqna` →
  `open_telco_teleqna_lm_eval_baseline`, `open_telco_3gpp_tsg` /
  `open_telco_3gpp_tsg_gen` → `*_lm_eval_baseline`, `open_telco_full_*` →
  `open_telco_full_*_lm_eval_baseline`.
- **Bare `open_telco_otlite` / `open_telco_otfull` are non-runnable** (the run scripts
  fail-fast with `exit 2`); pick `_gsma` (recommended) or `_lm_eval_baseline` (legacy)
  explicitly.
- `*_mcgen` is an MC scoring-sensitivity diagnostic and is unchanged by this rename.
- This repository does **not** claim "official full reproduction" of the GSMA stack.
- **Historical preservation**: past run numbers/paths are kept under their historical
  pre-rename names; do not retroactively rename historical results.

## Public leaderboard mapping

The public `GSMA/leaderboard` dataset has 7 benchmark columns. The **recommended**
mapping is the default `_gsma` profile (`*_mcgen` / `*_gsma` tasks); the legacy
`_lm_eval_baseline` mapping is **diagnostic only and not leaderboard-comparable**.

| Public column | Recommended ot-lite (`_gsma`) | Recommended ot-full (`_gsma`) | Legacy ot-lite (`_lm_eval_baseline`, diagnostic) | Legacy ot-full (`_lm_eval_baseline`, diagnostic) |
|---|---|---|---|---|
| `teleqna` | `open_telco_teleqna_mcgen` | `open_telco_full_teleqna_mcgen` | `open_telco_teleqna_lm_eval_baseline` | `open_telco_full_teleqna_lm_eval_baseline` |
| `teletables` | `open_telco_teletables_mcgen` | `open_telco_full_teletables_mcgen` | `open_telco_teletables_lm_eval_baseline` | `open_telco_full_teletables_lm_eval_baseline` |
| `oranbench` | `open_telco_oranbench_mcgen` | `open_telco_full_oranbench_mcgen` | `open_telco_oranbench_lm_eval_baseline` | `open_telco_full_oranbench_lm_eval_baseline` |
| `srsranbench` | `open_telco_srsranbench_mcgen` | `open_telco_full_srsranbench_mcgen` | `open_telco_srsranbench_lm_eval_baseline` | `open_telco_full_srsranbench_lm_eval_baseline` |
| `telemath` | `open_telco_telemath_gsma` | `open_telco_full_telemath_gsma` | `open_telco_telemath_lm_eval_baseline` | `open_telco_full_telemath_lm_eval_baseline` |
| `telelogs` | `open_telco_telelogs_gsma` | `open_telco_full_telelogs_gsma` | `open_telco_telelogs_lm_eval_baseline` | `open_telco_full_telelogs_lm_eval_baseline` |
| `three_gpp` | `open_telco_3gpp_tsg_gsma` | `open_telco_full_3gpp_tsg_gsma` | `open_telco_3gpp_tsg_gen_lm_eval_baseline` | `open_telco_full_3gpp_tsg_lm_eval_baseline` |

The recommended `_gsma` mapping is selected by `compare_gsma_leaderboard.py --profile gsma`
(see `GSMA_SCORING_CONTRACT.md`). The legacy `_lm_eval_baseline` mapping is the
`--profile default` mapping and exists for diagnostics only — it must not be reported as
a leaderboard comparison.

## Group tasks

### `open_telco_otlite_gsma` / `open_telco_otfull_gsma` (DEFAULT, recommended)

These are the run-script defaults and the only leaderboard-comparable groups. They are
documented in full in the "GSMA-aligned" subsection below.

### `open_telco_otlite_lm_eval_baseline` (legacy, diagnostic only)

Dataset: `GSMA/ot-lite`

Purpose: preserved legacy lm-eval/loglikelihood 7-task baseline (former bare
`open_telco_otlite`). **Diagnostic only — not leaderboard-comparable.** Use the
recommended `open_telco_otlite_gsma` for leaderboard comparison.

Group `metadata.version`: v0.2.

Aggregation: **sample-weighted** mean of the 7 task `acc` values. The group YAML
(`open_telco_otlite_lm_eval_baseline.yaml`) declares `aggregate_metric_list` with
`aggregation: mean` but does not override `weight_by_size`, so the lm_eval fork default
(`weight_by_size=True`) applies. This means the group `acc` is dominated by the
high-sample-count tasks (notably `teleqna`, 1000 samples). The unweighted task-mean
must be computed separately if equal per-task weighting is wanted.

Tasks:

```text
open_telco_teleqna_lm_eval_baseline
open_telco_teletables_lm_eval_baseline
open_telco_oranbench_lm_eval_baseline
open_telco_srsranbench_lm_eval_baseline
open_telco_telemath_lm_eval_baseline
open_telco_telelogs_lm_eval_baseline
open_telco_3gpp_tsg_gen_lm_eval_baseline
```

### `open_telco_otlite_core4_lm_eval_baseline` (legacy, diagnostic only)

Dataset: `GSMA/ot-lite`

Purpose: legacy starter bundle from the first implementation pass (former
`open_telco_otlite_core4`). **Diagnostic only — not leaderboard-comparable.**

Group `metadata.version`: v0.1.

Aggregation: **sample-weighted** mean (`weight_by_size: true`, explicit in the group YAML).

Tasks:

```text
open_telco_teleqna_lm_eval_baseline
open_telco_oranbench_lm_eval_baseline
open_telco_srsranbench_lm_eval_baseline
open_telco_3gpp_tsg_lm_eval_baseline
```

### `open_telco_otfull_lm_eval_baseline` (legacy, diagnostic only)

Dataset: `GSMA/ot-full`

Purpose: preserved legacy lm-eval/loglikelihood 7-task baseline (former bare
`open_telco_otfull`). **Diagnostic only — not leaderboard-comparable.** Use the
recommended `open_telco_otfull_gsma` for leaderboard comparison.

Group `metadata.version`: v0.2.

Aggregation: **sample-weighted** mean of the 7 task `acc` values. As with
`open_telco_otlite_lm_eval_baseline`, the group YAML
(`open_telco_otfull_lm_eval_baseline.yaml`) does not override `weight_by_size`, so the
lm_eval fork default (`weight_by_size=True`) applies.

Tasks:

```text
open_telco_full_teleqna_lm_eval_baseline
open_telco_full_teletables_lm_eval_baseline
open_telco_full_oranbench_lm_eval_baseline
open_telco_full_srsranbench_lm_eval_baseline
open_telco_full_telemath_lm_eval_baseline
open_telco_full_telelogs_lm_eval_baseline
open_telco_full_3gpp_tsg_lm_eval_baseline
```

### `open_telco_otlite_gsma` / `open_telco_otfull_gsma` (DEFAULT, recommended, GSMA-aligned)

Dataset: `GSMA/ot-lite` / `GSMA/ot-full`.

Purpose: the **default / recommended** GSMA-compatible profile (run-script default) whose
**scorers mirror the `gsma-evals` source** (`gsma-evals/src/evals/<task>/*.py`). Additive
only; the legacy `*_lm_eval_baseline` groups above are unchanged. See
`GSMA_SCORING_CONTRACT.md` for the per-task official contract and the scorer-aligned vs
engine-different split.

Group `metadata.version`: v0.1.

Aggregation: **unweighted task mean** (`weight_by_size: false`, explicit override of the
lm_eval fork default `weight_by_size=True`). The unweighted mean is a leaderboard
convention only; the official `run_evals.py` computes no cross-task average.

`open_telco_otlite_gsma` tasks:

```text
open_telco_teleqna_mcgen
open_telco_oranbench_mcgen
open_telco_srsranbench_mcgen
open_telco_teletables_mcgen
open_telco_telemath_gsma
open_telco_telelogs_gsma
open_telco_3gpp_tsg_gsma
```

`open_telco_otfull_gsma` tasks: the `open_telco_full_*` counterparts of the above.

> **MC engine is UNALIGNED**: the 4 MC `*_mcgen` tasks use free single-letter
> `generate_until` instead of the official constrained `multiple_choice(cot=False)`
> decoding. This is the largest unaligned axis and the dominant candidate-gap driver;
> the MC delta measures generation-vs-constrained-decoding sensitivity, not reproduction.

### New GSMA-aligned task rows

`max_gen_toks=256` (generation `*_gsma`) is a deliberate scorer-fit/cost choice (the
scorer reads only the last `\boxed{}` / first WG token), not a parity loss. `max_gen_toks=8`
(MC `*_mcgen`) matches the existing `*_mcgen` single-letter pattern.

| Task (otlite / otfull) | output_type | until | max_gen_toks | scorer rule (source) |
|---|---|---|---:|---|
| `open_telco_teletables_mcgen` / `open_telco_full_teletables_mcgen` | `generate_until` | `["\n"]` | 8 | free letter vs `int(answer)` 0-based; table NOT injected (`teletables.py:25,44-45`) |
| `open_telco_telemath_gsma` / `open_telco_full_telemath_gsma` | `generate_until` | `[]` | 256 | last `\boxed{}` → `isclose(rel_tol/abs_tol=0.01)` + exact fallback (`telemath.py:42-62`) |
| `open_telco_telelogs_gsma` / `open_telco_full_telelogs_gsma` | `generate_until` | `[]` | 256 | soft: first int of last `\boxed{}` vs first int of answer (`telelogs.py:41-54`) |
| `open_telco_3gpp_tsg_gsma` / `open_telco_full_3gpp_tsg_gsma` | `generate_until` | `[]` | 256 | first WG-token `([A-Z]+\d+(?:-[A-Z]+)?)` ignorecase vs raw answer (`three_gpp.py:12,30`) |

The pre-existing `open_telco_{teleqna,oranbench,srsranbench}_mcgen` (+ `_full_` and the
`open_telco_otlite_mcgen` / `open_telco_otfull_mcgen` groups) share the MC `*_mcgen`
pattern (`generate_until`, `until: ["\n"]`, `max_gen_toks: 8`). Optional collapse-gate
fallbacks `doc_to_text_telelogs_gsma_hinted` / `doc_to_text_3gpp_gsma_hinted` add a single
gold-free output-format line and are promoted to YAML only if the smoke emission-rate gate
triggers (see `GSMA_SCORING_CONTRACT.md` §2.3).

All `*_gsma` / `*_mcgen` task and group YAML carry `metadata.version: 0.1` and
`gsma_aligned: scorer-only`.

## Per-task `metadata.version`

The per-task YAML `metadata.version` values (legacy `_lm_eval_baseline` tasks) have
drifted; they are not uniformly "v0.2". Current values:

| Task | `metadata.version` |
|---|---|
| `open_telco_teleqna_lm_eval_baseline` | v0.1 |
| `open_telco_oranbench_lm_eval_baseline` | v0.1 |
| `open_telco_srsranbench_lm_eval_baseline` | v0.1 |
| `open_telco_3gpp_tsg_lm_eval_baseline` (MC) | v0.1 |
| `open_telco_otlite_core4_lm_eval_baseline` (group) | v0.1 |
| `open_telco_telemath_lm_eval_baseline` | v0.2 |
| `open_telco_telelogs_lm_eval_baseline` | v0.2 |
| `open_telco_teletables_lm_eval_baseline` | v0.2 |
| `open_telco_3gpp_tsg_gen_lm_eval_baseline` | v0.2 |
| `open_telco_otlite_lm_eval_baseline` (group) | v0.2 |

All `open_telco_full_*_lm_eval_baseline` tasks and the
`open_telco_otfull_lm_eval_baseline` group are v0.2.

## Generation settings (`max_gen_toks`)

Actual `generation_kwargs.max_gen_toks` values from the legacy `_lm_eval_baseline` task YAML:

| Task | `max_gen_toks` |
|---|---|
| `open_telco_telemath_lm_eval_baseline` / `open_telco_full_telemath_lm_eval_baseline` | 48 |
| `open_telco_telelogs_lm_eval_baseline` / `open_telco_full_telelogs_lm_eval_baseline` | 24 |
| `open_telco_3gpp_tsg_gen_lm_eval_baseline` / `open_telco_full_3gpp_tsg_lm_eval_baseline` | 32 |

## Task details

### TeleQnA

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks (recommended `_gsma`) | `open_telco_teleqna_mcgen`, `open_telco_full_teleqna_mcgen` |
| Local tasks (legacy, diagnostic) | `open_telco_teleqna_lm_eval_baseline`, `open_telco_full_teleqna_lm_eval_baseline` |
| Public column | `teleqna` |
| Type | multiple-choice |
| Metrics | `acc`, `acc_norm` where configured |
| Prompt helper | `utils.doc_to_text_mc` |
| Main risk | prompt and choice-label format may differ from official Inspect AI stack |

### TeleTables

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks (recommended `_gsma`) | `open_telco_teletables_mcgen`, `open_telco_full_teletables_mcgen` |
| Local tasks (legacy, diagnostic) | `open_telco_teletables_lm_eval_baseline`, `open_telco_full_teletables_lm_eval_baseline` |
| Public column | `teletables` |
| Type | multiple-choice table QA |
| Metrics | `acc`, `acc_norm` where configured |
| Prompt helper | `utils.doc_to_text_teletables` |
| Main risk | table content may be absent unless `TELETABLES_ROOT` points to extracted original TeleTables files |

### ORANBench

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks (recommended `_gsma`) | `open_telco_oranbench_mcgen`, `open_telco_full_oranbench_mcgen` |
| Local tasks (legacy, diagnostic) | `open_telco_oranbench_lm_eval_baseline`, `open_telco_full_oranbench_lm_eval_baseline` |
| Public column | `oranbench` |
| Type | multiple-choice |
| Metrics | `acc`, `acc_norm` where configured |
| Prompt helper | usually `utils.doc_to_text_mc` |
| Main risk | official scoring may use different prompt/choice conventions |

### srsRANBench

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks (recommended `_gsma`) | `open_telco_srsranbench_mcgen`, `open_telco_full_srsranbench_mcgen` |
| Local tasks (legacy, diagnostic) | `open_telco_srsranbench_lm_eval_baseline`, `open_telco_full_srsranbench_lm_eval_baseline` |
| Public column | `srsranbench` |
| Type | multiple-choice source-code understanding |
| Metrics | `acc`, `acc_norm` where configured |
| Prompt helper | usually `utils.doc_to_text_mc` |
| Main risk | code/context formatting and MC scoring style may differ from official stack |

### TeleMath

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks (recommended `_gsma`) | `open_telco_telemath_gsma`, `open_telco_full_telemath_gsma` |
| Local tasks (legacy, diagnostic) | `open_telco_telemath_lm_eval_baseline`, `open_telco_full_telemath_lm_eval_baseline` |
| Public column | `telemath` |
| Type | generation with numeric answer parsing |
| Metric | `acc` |
| Prompt helper | `utils.doc_to_text_telemath` |
| Parser | `utils.process_results_telemath` |
| Current generation settings | deterministic; legacy `max_gen_toks: 48`, recommended `_gsma` `max_gen_toks: 256` (per YAML) |
| Main risk | parser strictness, premature newline stop, units, rounding/tolerance, chain-of-thought vs final-answer formatting |

### TeleLogs

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks (recommended `_gsma`) | `open_telco_telelogs_gsma`, `open_telco_full_telelogs_gsma` |
| Local tasks (legacy, diagnostic) | `open_telco_telelogs_lm_eval_baseline`, `open_telco_full_telelogs_lm_eval_baseline` |
| Public column | `telelogs` |
| Type | generation with root-cause label parsing |
| Metric | `acc` |
| Prompt helper | `utils.doc_to_text_telelogs` |
| Parser | `utils.process_results_telelogs` |
| Expected labels | `C1` through `C8` |
| Main risk | long prompt truncation, parser strictness, answer-label extraction differences |

### 3GPP TSG / three_gpp

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks (recommended `_gsma`) | `open_telco_3gpp_tsg_gsma`, `open_telco_full_3gpp_tsg_gsma` |
| Local tasks (legacy, diagnostic) | `open_telco_3gpp_tsg_gen_lm_eval_baseline` (generation), `open_telco_3gpp_tsg_lm_eval_baseline` (MC, core4 only), `open_telco_full_3gpp_tsg_lm_eval_baseline` |
| Public column | `three_gpp` |
| Type | working-group classification |
| Metrics | `acc`, optionally `acc_norm` for MC variant |
| Prompt helpers | `utils.doc_to_text_3gpp_mc`, `utils.doc_to_text_3gpp_generate` |
| Parser | `utils.process_results_3gpp_generate` for generation variant |
| Expected labels | `CT1`, `CT3`, `CT4`, `CT6`, `RAN1`, `RAN2`, `RAN3`, `RAN4`, `RAN5`, `RAN_AH1`, `SA1`, `SA2`, `SA3`, `SA4`, `SA5`, `SA6` |
| Main risk | public stack may classify from a different excerpt/prompt format; generation JSON parser may be too strict or stop too early |

## Scripts

- `scripts/compare_gsma_leaderboard.py`: leaderboard comparison helper. Compares a local
  result JSON against a public `GSMA/leaderboard` row. `--profile {default,gsma}` selects
  the mapping: `default` maps the legacy `*_lm_eval_baseline` tasks (diagnostic only, not
  leaderboard-comparable); `gsma` (recommended) maps the `*_mcgen` / `*_gsma` tasks and
  emits a per-task delta table first, then a labeled unweighted mean, with an
  MC-engine-unaligned caveat. Historical pre-rename result JSONs used the bare task names
  (e.g. `open_telco_teleqna`); compare those with `--map public_col=old_task` overrides.

## Known global issues

1. Current tracked baseline is `ot-lite`, not `ot-full`.
2. Official GSMA stack is Inspect AI, not LM-Evaluation-Harness.
3. Public `gemma3-4b` may not exactly match local `google/gemma-3-4b-it`.
4. HF runs have shown truncation around 2024 tokens.
5. Some generation tasks may need better `until`, `max_gen_toks`, and parser behavior.
6. TeleTables requires original table content for a fairer evaluation.

## Next documentation work

- Add actual sample counts for each `ot-full` task after verifying task loading.
- Add exact YAML paths and version numbers for each task.
- Add output parser examples for correct/incorrect edge cases.
- Link each new experiment in `EXPERIMENTS.md`.
