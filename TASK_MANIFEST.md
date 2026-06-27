# Task manifest: Open Telco tasks in NFM-Eval-Harness

Last updated: 2026-06-27

This manifest describes the current LM-Evaluation-Harness task packs implemented in this repository.

## Public leaderboard mapping

The public `GSMA/leaderboard` dataset has 7 benchmark columns:

| Public column | Local ot-lite task | Local ot-full task |
|---|---|---|
| `teleqna` | `open_telco_teleqna` | `open_telco_full_teleqna` |
| `teletables` | `open_telco_teletables` | `open_telco_full_teletables` |
| `oranbench` | `open_telco_oranbench` | `open_telco_full_oranbench` |
| `srsranbench` | `open_telco_srsranbench` | `open_telco_full_srsranbench` |
| `telemath` | `open_telco_telemath` | `open_telco_full_telemath` |
| `telelogs` | `open_telco_telelogs` | `open_telco_full_telelogs` |
| `three_gpp` | `open_telco_3gpp_tsg_gen` | `open_telco_full_3gpp_tsg` |

For the non-default GSMA-aligned profile, the public columns map to the `*_mcgen` /
`*_gsma` tasks instead (see `compare_gsma_leaderboard.py --profile gsma` and
`GSMA_SCORING_CONTRACT.md`): `teleqna→*_teleqna_mcgen`, `teletables→*_teletables_mcgen`,
`oranbench→*_oranbench_mcgen`, `srsranbench→*_srsranbench_mcgen`, `telemath→*_telemath_gsma`,
`telelogs→*_telelogs_gsma`, `three_gpp→*_3gpp_tsg_gsma`.

## Group tasks

### `open_telco_otlite`

Dataset: `GSMA/ot-lite`

Purpose: quick 7-task leaderboard-style baseline.

Group `metadata.version`: v0.2.

Aggregation: **sample-weighted** mean of the 7 task `acc` values. The group YAML
(`open_telco_otlite.yaml`) declares `aggregate_metric_list` with `aggregation: mean`
but does not override `weight_by_size`, so the lm_eval fork default
(`weight_by_size=True`) applies. This means the group `acc` is dominated by the
high-sample-count tasks (notably `teleqna`, 1000 samples). The unweighted task-mean
must be computed separately if equal per-task weighting is wanted.

Tasks:

```text
open_telco_teleqna
open_telco_teletables
open_telco_oranbench
open_telco_srsranbench
open_telco_telemath
open_telco_telelogs
open_telco_3gpp_tsg_gen
```

### `open_telco_otlite_core4`

Dataset: `GSMA/ot-lite`

Purpose: legacy starter bundle from the first implementation pass.

Group `metadata.version`: v0.1.

Aggregation: **sample-weighted** mean (`weight_by_size: true`, explicit in the group YAML).

Tasks:

```text
open_telco_teleqna
open_telco_oranbench
open_telco_srsranbench
open_telco_3gpp_tsg
```

### `open_telco_otfull`

Dataset: `GSMA/ot-full`

Purpose: 7-task leaderboard-oriented baseline.

Group `metadata.version`: v0.2.

Aggregation: **sample-weighted** mean of the 7 task `acc` values. As with
`open_telco_otlite`, the group YAML (`open_telco_otfull.yaml`) does not override
`weight_by_size`, so the lm_eval fork default (`weight_by_size=True`) applies.

Tasks:

```text
open_telco_full_teleqna
open_telco_full_teletables
open_telco_full_oranbench
open_telco_full_srsranbench
open_telco_full_telemath
open_telco_full_telelogs
open_telco_full_3gpp_tsg
```

### `open_telco_otlite_gsma` / `open_telco_otfull_gsma` (NON-DEFAULT, GSMA-aligned)

Dataset: `GSMA/ot-lite` / `GSMA/ot-full`.

Purpose: non-default profile whose **scorers mirror the `gsma-evals` source**
(`gsma-evals/src/evals/<task>/*.py`). Additive only; the default groups above are
unchanged. See `GSMA_SCORING_CONTRACT.md` for the per-task official contract and the
scorer-aligned vs engine-different split.

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

The per-task YAML `metadata.version` values have drifted; they are not uniformly
"v0.2". Current values:

| Task | `metadata.version` |
|---|---|
| `open_telco_teleqna` | v0.1 |
| `open_telco_oranbench` | v0.1 |
| `open_telco_srsranbench` | v0.1 |
| `open_telco_3gpp_tsg` (MC) | v0.1 |
| `open_telco_otlite_core4` (group) | v0.1 |
| `open_telco_telemath` | v0.2 |
| `open_telco_telelogs` | v0.2 |
| `open_telco_teletables` | v0.2 |
| `open_telco_3gpp_tsg_gen` | v0.2 |
| `open_telco_otlite` (group) | v0.2 |

All `open_telco_full_*` tasks and the `open_telco_otfull` group are v0.2.

## Generation settings (`max_gen_toks`)

Actual `generation_kwargs.max_gen_toks` values from the task YAML:

| Task | `max_gen_toks` |
|---|---|
| `open_telco_telemath` / `open_telco_full_telemath` | 48 |
| `open_telco_telelogs` / `open_telco_full_telelogs` | 24 |
| `open_telco_3gpp_tsg_gen` / `open_telco_full_3gpp_tsg` | 32 |

## Task details

### TeleQnA

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks | `open_telco_teleqna`, `open_telco_full_teleqna` |
| Public column | `teleqna` |
| Type | multiple-choice |
| Metrics | `acc`, `acc_norm` where configured |
| Prompt helper | `utils.doc_to_text_mc` |
| Main risk | prompt and choice-label format may differ from official Inspect AI stack |

### TeleTables

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks | `open_telco_teletables`, `open_telco_full_teletables` |
| Public column | `teletables` |
| Type | multiple-choice table QA |
| Metrics | `acc`, `acc_norm` where configured |
| Prompt helper | `utils.doc_to_text_teletables` |
| Main risk | table content may be absent unless `TELETABLES_ROOT` points to extracted original TeleTables files |

### ORANBench

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks | `open_telco_oranbench`, `open_telco_full_oranbench` |
| Public column | `oranbench` |
| Type | multiple-choice |
| Metrics | `acc`, `acc_norm` where configured |
| Prompt helper | usually `utils.doc_to_text_mc` |
| Main risk | official scoring may use different prompt/choice conventions |

### srsRANBench

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks | `open_telco_srsranbench`, `open_telco_full_srsranbench` |
| Public column | `srsranbench` |
| Type | multiple-choice source-code understanding |
| Metrics | `acc`, `acc_norm` where configured |
| Prompt helper | usually `utils.doc_to_text_mc` |
| Main risk | code/context formatting and MC scoring style may differ from official stack |

### TeleMath

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks | `open_telco_telemath`, `open_telco_full_telemath` |
| Public column | `telemath` |
| Type | generation with numeric answer parsing |
| Metric | `acc` |
| Prompt helper | `utils.doc_to_text_telemath` |
| Parser | `utils.process_results_telemath` |
| Current generation settings | deterministic, `max_gen_toks: 48` (per YAML) |
| Main risk | parser strictness, premature newline stop, units, rounding/tolerance, chain-of-thought vs final-answer formatting |

### TeleLogs

| Item | Value |
|---|---|
| Dataset | `GSMA/ot-lite` / `GSMA/ot-full` |
| Local tasks | `open_telco_telelogs`, `open_telco_full_telelogs` |
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
| Local tasks | `open_telco_3gpp_tsg`, `open_telco_3gpp_tsg_gen`, `open_telco_full_3gpp_tsg` |
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
  the mapping: `default` (byte-identical to prior behavior) maps the legacy tasks; `gsma`
  maps the `*_mcgen` / `*_gsma` tasks and emits a per-task delta table first, then a
  labeled unweighted mean, with an MC-engine-unaligned caveat.

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
