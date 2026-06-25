# Task manifest: Open Telco tasks in NFM-Eval-Harness

Last updated: 2026-06-25

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

## Group tasks

### `open_telco_otlite`

Dataset: `GSMA/ot-lite`

Purpose: quick 7-task leaderboard-style baseline.

Aggregation: unweighted mean of the 7 task `acc` values.

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

Aggregation: unweighted mean of the 7 task `acc` values.

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
| Current generation settings | deterministic, limited `max_gen_toks`; exact values in YAML |
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
