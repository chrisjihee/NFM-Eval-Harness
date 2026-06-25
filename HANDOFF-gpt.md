# Handoff: NFM-Eval-Harness

Last updated: 2026-06-25

## 1. Why this repository exists

This repository supports the ETRI NFM-LLM work package in the government R&D project `차세대 네트워크 AI 파운데이션 모델 개발`.

The ETRI Language Intelligence Lab was asked to contribute because it has experience running, fine-tuning, and evaluating LLMs. The Intelligent Network Lab leads the overall NFM project, network-domain data, PoC scenarios, and domain validation. POSTECH DPNM Lab leads the official NFM benchmark evaluation framework across LLM/LMM/LAM.

This repository is the Language Intelligence Lab's practical LLM evaluation harness:

- run GSMA Open Telco AI tasks with LM-Evaluation-Harness;
- compare candidate NFM-LLM base models;
- measure domain-adaptation effects;
- provide a reusable language-model evaluation module that can later connect to POSTECH's official NFM benchmark design.

## 2. What NFM-LLM means in this project

NFM-LLM is not just a document QA chatbot. In project discussions, it has two major roles:

1. Network knowledge understanding, reasoning, and generation.
   - 3GPP/O-RAN/manual QA.
   - alarm correlation analysis.
   - root-cause diagnosis.
   - natural-language operational report generation.

2. Agentic AI brain / planning.
   - interpret high-level network intent/policy;
   - generate executable `Recipe` / `Coordination Sheet`;
   - decide which LMM/LAM/tool/MCP/NETCONF/API calls are needed;
   - include KPI observation, loop period, safety constraints, verification and rollback conditions.

The current repository only covers the first baseline layer: Open Telco LLM benchmark execution. NFM-specific tasks such as Intent-to-Recipe and RAG-grounded QA are planned later.

## 3. Relationship to POSTECH benchmark work

POSTECH is responsible for the official NFM benchmark evaluation framework:

- benchmark concept and requirements;
- metrics and measurement methods;
- model-specific scenarios for LLM/LMM/LAM;
- datasets and digital-twin/PoC verification;
- official evaluation software and reports.

This repo should not duplicate that entire responsibility.

This repo should provide the LLM evaluation execution module:

- lm-eval custom tasks;
- model runners;
- baseline model comparison;
- result summaries;
- Open Telco AI alignment notes;
- later NFM-LLM-specific task adapters.

## 4. Current repository status

The repository is public:

```text
https://github.com/chrisjihee/NFM-Eval-Harness
```

Current README definition:

- lightweight evaluation harness for NFM-LLM baseline evaluation;
- uses GSMA Open Telco benchmark tasks;
- defines `GSMA/ot-lite` and `GSMA/ot-full` as lm-eval custom tasks;
- runs on GPU server with Hugging Face or vLLM backend.

Current task packs:

```text
open_telco_lm_eval/tasks/open_telco_otlite
open_telco_lm_eval/tasks/open_telco_otfull
```

Current runners:

```text
run_open_telco_otlite.sh
run_open_telco_otfull.sh
```

Current documentation:

```text
README.md
PLAN.md
PROGRESS.md
EXPERIMENTS.md
outputs/latest-summary.md
open_telco_lm_eval/README.md
AGENTS.md
CLAUDE.md
```

## 5. Implemented task groups

### 5.1 `open_telco_otlite`

7-task leaderboard-style comparison pack using `GSMA/ot-lite`:

```text
open_telco_teleqna
open_telco_teletables
open_telco_oranbench
open_telco_srsranbench
open_telco_telemath
open_telco_telelogs
open_telco_3gpp_tsg_gen
```

Aggregation:

```text
unweighted mean of acc across 7 tasks
```

### 5.2 `open_telco_otlite_core4`

Legacy 4-task starter pack:

```text
open_telco_teleqna
open_telco_oranbench
open_telco_srsranbench
open_telco_3gpp_tsg
```

This preserves the initial implementation path.

### 5.3 `open_telco_otfull`

7-task leaderboard-oriented pack using `GSMA/ot-full`:

```text
open_telco_full_teleqna
open_telco_full_teletables
open_telco_full_oranbench
open_telco_full_srsranbench
open_telco_full_telemath
open_telco_full_telelogs
open_telco_full_3gpp_tsg
```

Aggregation:

```text
unweighted mean of acc across 7 tasks
```

## 6. Current baseline result

Current tracked baseline:

```text
Date: 2026-05-15
Model: google/gemma-3-4b-it
Backend: hf
Task group: open_telco_otlite
Average acc: 0.3718
Result file: results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.md
```

Task-wise result:

| Task | Local score |
|---|---:|
| `open_telco_teleqna` | 0.4500 |
| `open_telco_teletables` | 0.2000 |
| `open_telco_oranbench` | 0.3667 |
| `open_telco_srsranbench` | 0.5467 |
| `open_telco_telemath` | 0.0100 |
| `open_telco_telelogs` | 0.1700 |
| `open_telco_3gpp_tsg_gen` | 0.0700 |
| Average | 0.3718 |

Interpretation:

- Stronger local areas: `srsranbench`, `teleqna`.
- Weaker local areas: `telemath`, `3gpp_tsg_gen`, `telelogs`.
- Long prompt truncation warnings were observed in generation-heavy tasks, so generation task results are not yet fully stable.

## 7. Public leaderboard comparison concern

The user is concerned about the public GSMA leaderboard row for Gemma 3 4B:

```text
model: gemma3-4b
provider: Google
rank: 78
average: 0.397
benchmarks_completed: 7
```

Public scores from `GSMA/leaderboard`:

| Column | Public score |
|---|---:|
| `teleqna` | 0.652333 |
| `teletables` | 0.273333 |
| `oranbench` | 0.660000 |
| `srsranbench` | 0.740000 |
| `telemath` | 0.136667 |
| `telelogs` | 0.116667 |
| `three_gpp` | 0.200000 |
| `average` | 0.397000 |

Important note:

- The local average 0.3718 is not extremely far from 0.397.
- But the task-wise values differ a lot.
- Current local result is `ot-lite`; public leaderboard is leaderboard/full-style score.
- The official GSMA stack is Inspect AI based, while this repo is lm-eval based.
- We need to improve alignment and document remaining differences.

## 8. Likely mismatch causes to investigate

### Dataset/split mismatch

- `ot-lite` is a development subset.
- Public leaderboard scores may correspond more closely to `ot-full` or another curated subset.
- Direct `ot-lite` vs public leaderboard comparison is not valid.

### Model identity mismatch

- Public row says `gemma3-4b`.
- Local run uses `google/gemma-3-4b-it`.
- Verify whether the official row used instruct, base, or another served variant.

### Official stack mismatch

- GSMA official eval is Inspect AI based.
- This repo uses LM-Evaluation-Harness.
- Prompt templates, scoring, parsing, and answer extraction can differ.

### Multiple-choice scoring mismatch

- lm-eval multiple-choice uses loglikelihood over choices.
- Official stack may use generated answer extraction or different prompt templates.
- Chat template can have large effects for instruction models.

### Generation parsing mismatch

Affected tasks:

- `telemath`
- `telelogs`
- `3gpp_tsg_gen`

Possible problems:

- `until: ["\n"]` may stop too early.
- `max_gen_toks` may be too small.
- Parser may be too strict.
- Prompt may not match official format.

### Prompt truncation

The current HF run emitted warnings such as:

```text
Left truncation applied. Original sequence length was 2902, truncating to last 2024 tokens.
```

This can destroy TeleLogs and other long-context task inputs. Investigate max context length/model args/prompt length.

### TeleTables missing table content

`utils.py` supports table content injection through `TELETABLES_ROOT`, but if the original table files are absent, the model only sees metadata and choices. Public evaluation may use richer table context.

## 9. Immediate tasks for Claude Code

### A. Documentation and manifest

Create or update:

- `TASK_MANIFEST.md`
- `REPRODUCTION_NOTES.md`
- `TROUBLESHOOTING.md`
- `ENVIRONMENT.md` if needed

`TASK_MANIFEST.md` should include for each task:

- task name;
- dataset path/config;
- split;
- output type;
- metric;
- parser;
- prompt function;
- known issue;
- public leaderboard column mapping.

### B. Add comparison utility

Add:

```text
scripts/compare_gsma_leaderboard.py
```

Expected behavior:

```bash
python scripts/compare_gsma_leaderboard.py \
  --model gemma3-4b \
  --local-result results/open_telco_otlite/google__gemma-3-4b-it/results_2026-05-15T15-40-57.791797.json
```

Output:

- public score table;
- local score table;
- task name mapping;
- deltas;
- Markdown and/or CSV output.

### C. Add smoke-test path

Add a lightweight script or README commands to confirm task loading without full GPU evaluation.

Examples:

```bash
TASKS=open_telco_teleqna MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

or directly:

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

### D. Re-run and compare Gemma 3 4B

Run, if GPU is available:

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

Also test vLLM if feasible:

```bash
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

### E. Diagnose top discrepancies

Focus on:

1. `teleqna`
2. `oranbench`
3. `srsranbench`
4. `telemath`
5. `3gpp_tsg_gen`
6. truncation warnings
7. TeleTables table content availability

Do not overfit. The goal is credible alignment, not hiding differences.

## 10. Definition of done for the current pass

The current pass is complete when:

- `CLAUDE.md` is present and useful.
- `HANDOFF_NFM_EVAL_HARNESS.md` is present.
- task manifest and reproduction notes exist.
- current local Gemma 3 4B result can be compared with public leaderboard row using a script or documented manual table.
- `ot-lite` 7-task status is clear.
- `ot-full` 7-task status is clear.
- known mismatches are documented.
- `PROGRESS.md`, `EXPERIMENTS.md`, `outputs/latest-summary.md` are updated after any new run.

## 11. How to explain the result to the project team

Recommended wording:

> NFM-Eval-Harness is an LM-Evaluation-Harness based internal baseline evaluator for GSMA Open Telco AI tasks. It currently supports ot-lite and ot-full 7-task packs with HF and vLLM backends. The current Gemma 3 4B ot-lite baseline is 0.3718 average accuracy, while the public GSMA leaderboard row for gemma3-4b reports 0.397. The average gap is modest, but task-level differences remain because the public leaderboard uses an Inspect AI based official stack and may use different prompts, splits, and scoring. The next step is to align ot-full execution, add a leaderboard comparison script, document task-level deltas, and fix clear implementation issues such as long-prompt truncation and generation parser strictness.
