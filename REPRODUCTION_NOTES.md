# Reproduction notes: GSMA Open Telco leaderboard alignment

Last updated: 2026-06-25

## Purpose

This document explains how local `NFM-Eval-Harness` results should be compared with the public GSMA Open Telco AI leaderboard.

The goal is not to hide differences. The goal is to make the differences measurable, explainable, and, where implementation-related, fixable.

## Public reference

Public leaderboard dataset:

```text
https://huggingface.co/datasets/GSMA/leaderboard
```

Public Space:

```text
https://huggingface.co/spaces/GSMA/open-telco-leaderboard
```

The public dataset has these benchmark columns:

```text
teleqna
teletables
oranbench
srsranbench
telemath
telelogs
three_gpp
```

Each benchmark cell stores a pair:

```text
[score, stderr]
```

## Gemma 3 4B public row

Current public row to use as the first reproduction target:

| Field | Value |
|---|---:|
| model | `gemma3-4b` |
| provider | `Google` |
| rank | 78 |
| average | 0.397 |
| benchmarks_completed | 7 |

Public task scores:

| Benchmark column | Public score |
|---|---:|
| `teleqna` | 0.652333 |
| `teletables` | 0.273333 |
| `oranbench` | 0.660000 |
| `srsranbench` | 0.740000 |
| `telemath` | 0.136667 |
| `telelogs` | 0.116667 |
| `three_gpp` | 0.200000 |
| `average` | 0.397000 |

## Current local baseline

Current tracked local result:

```text
model: google/gemma-3-4b-it
backend: hf
task group: open_telco_otlite
result file: results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.md
```

Local task scores:

| Local task | Local score | Public mapping |
|---|---:|---|
| `open_telco_teleqna` | 0.4500 | `teleqna` |
| `open_telco_teletables` | 0.2000 | `teletables` |
| `open_telco_oranbench` | 0.3667 | `oranbench` |
| `open_telco_srsranbench` | 0.5467 | `srsranbench` |
| `open_telco_telemath` | 0.0100 | `telemath` |
| `open_telco_telelogs` | 0.1700 | `telelogs` |
| `open_telco_3gpp_tsg_gen` | 0.0700 | `three_gpp` |
| `open_telco_otlite` | 0.3718 | `average` |

## Aggregation method (read this before comparing averages)

The earlier "about 2.5 percentage points" statement was an aggregation-method mismatch,
not a like-for-like comparison. The two "averages" are computed differently:

- Local group `acc = 0.3718` (`open_telco_otlite`) is **sample-weighted**. The group YAML
  does not override `weight_by_size`, so the lm_eval fork default `weight_by_size=True`
  applies, and the high-sample-count `teleqna` task (1000 samples) dominates the group score.
- The public leaderboard `average = 0.397` is an **unweighted task mean** (equal weight per
  benchmark column).
- The local **unweighted 7-task simple mean** of the same task scores is **0.259**.

Comparing on the same basis (local unweighted task mean `0.259` vs public unweighted task
mean `0.397`) gives a real gap of about **−13.8 percentage points** — far larger than the
earlier "−2.5 pp" figure, which compared a sample-weighted number against an unweighted one.

This −13.8 pp figure is a candidate gap, not a settled conclusion: it still mixes `ot-lite`
(local) against the public leaderboard and carries the attribution caveats below.

The largest task-level drops are the three multiple-choice tasks:
`oranbench` (−0.293), `teleqna` (−0.202), and `srsranbench` (−0.193). `telelogs` is the only
task where local is higher (+0.053).

### Attribution caveat (UNKNOWN inputs)

Two inputs needed to attribute the gap are currently UNKNOWN, so the cause is undetermined:

- the exact extraction/scoring method behind the official GSMA leaderboard numbers; and
- which `gemma3-4b` variant (instruct / base / API-served / specific revision) produced the
  public row.

Until both are known, treat the gap as observed, not explained.

## Initial interpretation

The local sample-weighted group `acc 0.3718` and the public unweighted task mean `0.397`
are not directly comparable (see "Aggregation method" above). On a like-for-like
unweighted-task-mean basis the local value is `0.259`, a candidate gap of about −13.8 pp.

Task-level gaps are large and need diagnosis.

Approximate local-vs-public deltas:

| Benchmark | Local | Public | Delta |
|---|---:|---:|---:|
| `teleqna` | 0.4500 | 0.652333 | -0.202333 |
| `teletables` | 0.2000 | 0.273333 | -0.073333 |
| `oranbench` | 0.3667 | 0.660000 | -0.293300 |
| `srsranbench` | 0.5467 | 0.740000 | -0.193300 |
| `telemath` | 0.0100 | 0.136667 | -0.126667 |
| `telelogs` | 0.1700 | 0.116667 | +0.053333 |
| `three_gpp` | 0.0700 | 0.200000 | -0.130000 |

Average comparison (note the two methods are not interchangeable):

| Metric | Local | Public | Delta |
|---|---:|---:|---:|
| sample-weighted group `acc` (local) | 0.3718 | — | — |
| unweighted 7-task mean | 0.259 | 0.397000 | -0.138 |

The `0.3718` group score is sample-weighted and must not be subtracted from the public
unweighted `0.397`; the earlier `-0.0252` "average delta" came from doing exactly that. The
defensible same-basis delta is the unweighted-task-mean row: about **−13.8 pp** (candidate,
not settled).

The discrepancy pattern suggests that the local and public evaluations are not aligned at the task/sample/prompt/scoring level.

## Known reasons local scores may differ

### 1. Official GSMA stack differs

The public GSMA benchmark stack is Inspect AI based. This repository is LM-Evaluation-Harness based.

Possible differences:

- prompt text;
- system/user/chat formatting;
- answer extraction;
- scorer;
- generation parameters;
- model serving path;
- dataset subset.

### 2. `ot-lite` is not public leaderboard/full score

The current local baseline is `open_telco_otlite`, not `open_telco_otfull`.

Do not compare `ot-lite` scores directly against public leaderboard scores as if they were the same dataset.

### 3. Model name may differ

Public row:

```text
gemma3-4b
```

Local model:

```text
google/gemma-3-4b-it
```

Check whether public row used the instruct variant, base variant, an API-served variant, or a different revision.

### 4. Multiple-choice scoring may differ

Current lm-eval MCQ tasks use loglikelihood scoring over choices.

Official stack may use generated answer selection or a different answer-label prompt. This can strongly affect instruction-tuned models.

### 5. Chat template effects

The runner currently uses:

```text
--apply_chat_template
```

This may improve or harm depending on task format and model. Compare with and without chat template on a small subset before changing defaults.

### 6. Generation parser effects

Affected tasks:

- `telemath`
- `telelogs`
- `3gpp_tsg_gen`

Current generation tasks depend on custom parser logic. If the model outputs a correct answer with extra text that the parser misses, score can be artificially low.

### 7. Prompt truncation

Known warning from current HF run:

```text
Left truncation applied. Original sequence length was 2902, truncating to last 2024 tokens. Some content will be lost.
```

This must be investigated because it can destroy long-context inputs, especially TeleLogs and table/standard excerpts.

### 8. TeleTables table content

`TELETABLES_ROOT` can inject original table files. Without it, public rows may have insufficient table content for faithful reproduction.

## Result tracking policy

Curated `results_*.json` + `results_*.md` files are intentionally git-tracked as baseline
evidence. Large per-sample dumps and raw logs (`*_samples_*.jsonl`, `samples_*.jsonl`,
`*.log`, `*.tmp` under `results/**`) are excluded via `.gitignore`.

## Recommended reproduction procedure

### Step 1. Confirm task loading (bounded smoke)

Run a bounded smoke first so a copy-paste never triggers a full GPU run. The runner
enforces this via the `LIMIT` guard:

```bash
LIMIT=5 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

If you must call `lm_eval` directly, always pass `--limit`:

```bash
lm_eval \
  --model hf \
  --model_args pretrained=google/gemma-3-4b-it \
  --include_path ./open_telco_lm_eval/tasks \
  --tasks open_telco_teleqna \
  --limit 5 \
  --device cuda:0 \
  --batch_size auto \
  --apply_chat_template
```

### Step 2. Re-run `ot-lite` (full run, explicit confirm)

A full run requires an explicit confirmation flag:

```bash
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

### Step 3. Run `ot-full` (full run, explicit confirm)

```bash
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

This is the more relevant comparison target for public leaderboard alignment.

### Step 4. Compare with public row

After implementing the comparison script:

```bash
python scripts/compare_gsma_leaderboard.py \
  --model gemma3-4b \
  --local-result <path-to-local-result-json>
```

### Step 5. Diagnose per task

Work from the largest deltas:

1. `oranbench`
2. `teleqna`
3. `srsranbench`
4. `three_gpp`
5. `telemath`
6. `teletables`
7. `telelogs`

For each:

- inspect prompt;
- inspect one or more raw examples;
- compare local sample count to public/full sample count;
- verify answer mapping;
- check parser behavior;
- test with and without chat template;
- test generation vs multiple-choice scoring where appropriate.

## What is acceptable

Acceptable:

- Local `ot-lite` average differs from public leaderboard but is documented.
- Local `ot-full` result is closer but not identical because official stack is Inspect AI.
- Task-level differences are documented with suspected causes.
- Clear bugs, truncation issues, and parser problems are fixed.

Not acceptable:

- Claiming leaderboard reproduction without evidence.
- Comparing `ot-lite` directly to public leaderboard without caveat.
- Ignoring task-level deltas.
- Hiding parser/truncation issues.

## Target outcome

The target outcome is a defensible statement like this:

> Using the lm-eval based NFM-Eval-Harness, Gemma 3 4B obtains X on ot-lite and Y on ot-full. The public GSMA leaderboard reports 0.397 for gemma3-4b. The remaining delta is explained by dataset split, prompt/scoring differences between lm-eval and Inspect AI, model variant uncertainty, and known table/context issues. The harness is therefore suitable for internal relative comparison and domain-adaptation tracking, while official leaderboard reproduction would require matching GSMA's Inspect AI configuration exactly.
