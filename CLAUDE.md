# CLAUDE.md

This file is the primary working guide for Claude Code in this repository.

## Mission

Finish the `NFM-Eval-Harness` MVP for the ETRI NFM-LLM work package.

The near-term goal is to make this repository a reproducible, well-documented LM-Evaluation-Harness based baseline evaluator for GSMA Open Telco AI tasks, then run and explain Gemma 3 4B results against the public GSMA leaderboard.

Do not try to turn this repository into the complete official NFM benchmark framework. POSTECH is responsible for the official NFM benchmark evaluation framework across LLM/LMM/LAM. This repository is the language-model evaluation module/baseline harness owned by the ETRI Language Intelligence Lab.

## Project context

- Project: ETRI large government R&D project, `차세대 네트워크 AI 파운데이션 모델 개발`.
- Our lab: ETRI Language Intelligence Lab.
- Partner lab: Intelligent Network Lab.
- NFM-LLM role: language-based network knowledge understanding, alarm/RCA reasoning, natural-language reporting, and planning/recipe generation for Agentic AI.
- This repo role: evaluate candidate NFM-LLM base models and domain-adapted variants on telecom-domain LLM tasks.

## Important positioning

This repo is an internal NFM-LLM baseline harness, not a perfect clone of the official GSMA leaderboard stack.

However, we need the Gemma 3 4B result to be reasonably close to the public leaderboard so that the harness is credible. The public `GSMA/leaderboard` dataset currently lists `gemma3-4b` at rank 78 with average `0.397` across 7 benchmark columns. The current local `ot-lite` baseline for `google/gemma-3-4b-it` is `0.3718`. The average is not far away, but task-level discrepancies and evaluation-method differences must be explained and reduced where feasible.

## Read these files first

Before coding, read in this order:

1. `README.md`
2. `HANDOFF_NFM_EVAL_HARNESS.md`
3. `PLAN.md`
4. `PROGRESS.md`
5. `EXPERIMENTS.md`
6. `outputs/latest-summary.md`
7. `open_telco_lm_eval/README.md`
8. `AGENTS.md`
9. `ENVIRONMENT.md` if present
10. `TROUBLESHOOTING.md` if present

Then inspect:

- `run_open_telco_otlite.sh`
- `run_open_telco_otfull.sh`
- `open_telco_lm_eval/tasks/open_telco_otlite/*.yaml`
- `open_telco_lm_eval/tasks/open_telco_otfull/*.yaml`
- `open_telco_lm_eval/tasks/open_telco_otlite/utils.py`
- `open_telco_lm_eval/tasks/open_telco_otfull/utils.py`
- latest files under `results/`

## Operating rules

1. Always run `git status` before making changes.
2. Do not delete or overwrite user work unless explicitly asked.
3. Keep changes small and reviewable.
4. Prefer improving existing YAML task definitions and `utils.py` parsers over introducing another framework.
5. Do not replace LM-Evaluation-Harness with Inspect AI. You may add notes or optional comparison scripts, but the main implementation remains lm-eval based.
6. Do not run long GPU jobs without first confirming the available GPU environment.
7. If no GPU is available, implement code/documentation and provide exact commands for the user to run locally.
8. Keep benchmark outputs lightweight in git. Do not commit model caches, large raw logs, checkpoints, or huge generated artifacts.
9. Any evaluation-affecting change must update `PROGRESS.md` and, if a run is performed, `EXPERIMENTS.md` and `outputs/latest-summary.md`.
10. When results do not match the public leaderboard, document the exact suspected reason instead of hiding the mismatch.

## Current implementation summary

Implemented:

- `ot-lite` task pack using `GSMA/ot-lite`.
- `ot-full` task pack using `GSMA/ot-full`.
- `open_telco_otlite` 7-task group.
- `open_telco_otfull` 7-task group.
- Legacy `open_telco_otlite_core4` 4-task group.
- HF backend runner.
- vLLM backend runner.
- Custom parsers for generation-heavy tasks:
  - `3gpp_tsg_gen`
  - `telemath`
  - `telelogs`
  - `teletables` table-content injection support through `TELETABLES_ROOT`.

Known current baseline:

- Date: 2026-05-15
- Model: `google/gemma-3-4b-it`
- Backend: `hf`
- Task group: `open_telco_otlite`
- Average `acc`: `0.3718`

Task-level local `ot-lite` result:

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

Public `GSMA/leaderboard` row for `gemma3-4b` to compare against:

| Column | Public score |
|---|---:|
| `average` | 0.397 |
| `teleqna` | 0.652333 |
| `teletables` | 0.273333 |
| `oranbench` | 0.660000 |
| `srsranbench` | 0.740000 |
| `telemath` | 0.136667 |
| `telelogs` | 0.116667 |
| `three_gpp` | 0.200000 |

## Main concern to resolve

The user is worried that Gemma 3 4B is rank 78 with average 39.7 on the public GSMA leaderboard, but this repo's result should not be too far from that.

Important interpretation:

- The current local average `0.3718` is about 37.18%, so it is roughly 2.52 percentage points below the public average 39.7%.
- The average gap is not catastrophic.
- But task-level gaps are large for several tasks, especially `teleqna`, `oranbench`, `srsranbench`, `telemath`, and `three_gpp`.
- Because local result is `ot-lite` and public row is leaderboard/full-style score, direct one-to-one comparison is not valid until we run `ot-full` and align prompt/parser/scoring more carefully.

## Reproduction and diagnosis priorities

Work in this order:

### 1. Establish reproducible current baseline

- Confirm current repository runs.
- Add or verify a smoke-test path with `--limit 1` or small task subsets.
- Confirm `open_telco_otlite` and `open_telco_otfull` task loading works.
- Do not start with a full multi-hour run.

Suggested commands:

```bash
./setup-pre.sh
./setup-main.sh
./setup-post.sh

MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_teleqna BATCH_SIZE=auto ./run_open_telco_otlite.sh
MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otlite BATCH_SIZE=auto ./run_open_telco_otlite.sh
MODEL_NAME=google/gemma-3-4b-it TASKS=open_telco_otfull BATCH_SIZE=auto ./run_open_telco_otfull.sh
```

If using vLLM:

```bash
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

### 2. Compare against public leaderboard correctly

Implement a small comparison utility, for example:

```bash
python scripts/compare_gsma_leaderboard.py \
  --model gemma3-4b \
  --local-result results/open_telco_otlite/google__gemma-3-4b-it/results_*.json
```

The utility should:

- Load `GSMA/leaderboard` with `datasets`.
- Locate the row `model == "gemma3-4b"`.
- Extract public 7 scores.
- Load local lm-eval result JSON.
- Normalize task names.
- Produce Markdown/CSV delta tables.

### 3. Investigate task-level discrepancies

Check these possible causes:

- Official stack is Inspect AI, not lm-eval.
- `ot-lite` is not the same sample set as the public leaderboard/full benchmark.
- The public row uses model name `gemma3-4b`, while local uses `google/gemma-3-4b-it`; verify whether official used instruct or base variant if possible.
- Multiple-choice tasks may differ between loglikelihood scoring and generated-answer scoring.
- `--apply_chat_template` can change performance significantly.
- Prompt format may be too verbose or not aligned with official prompts.
- Choice labels A/B/C/D may not match original numeric choice labels.
- Generation tasks may be harmed by `until: ["\n"]` or too-small `max_gen_toks`.
- Parser strictness can turn partly-correct answers into zero score.
- TeleTables may be missing original table content unless `TELETABLES_ROOT` is set.
- Long prompts are being truncated around 2024 tokens in current HF runs; this must be investigated.
- vLLM and HF may differ due to chat template, max model length, logprobs, and tokenizer behavior.

### 4. Fix the most likely implementation issues

Start with low-risk improvements:

- Add `TASK_MANIFEST.md` with each task's dataset, split, output type, metric, parser, and known issue.
- Add `REPRODUCTION_NOTES.md` for leaderboard alignment.
- Add comparison script and delta report.
- Improve prompt/parsing where evidence shows a mismatch.
- Add parser unit tests with representative outputs.
- Reduce or eliminate truncation by setting model max length correctly for HF/vLLM or shortening prompt templates.
- Preserve both original and improved variants if changes could affect previous results.

### 5. Run model tests

Minimum desired runs:

- `google/gemma-3-4b-it` on `open_telco_otlite`, HF backend.
- `google/gemma-3-4b-it` on `open_telco_otfull`, HF backend if feasible.
- vLLM run for either full group or selected representative tasks.

If time/GPU allows, add 1-2 comparison models:

- `Qwen/Qwen2.5-1.5B-Instruct`
- a 7B/8B model available in the local cache or approved by the user.

## Expected deliverables

At completion, the repo should contain:

1. Updated `README.md` if execution or scope changed.
2. `TASK_MANIFEST.md` explaining all 7 tasks for `ot-lite` and `ot-full`.
3. `REPRODUCTION_NOTES.md` explaining how local results relate to GSMA public leaderboard.
4. `scripts/compare_gsma_leaderboard.py` or equivalent.
5. Smoke-test command or script.
6. Updated `PROGRESS.md`.
7. Updated `EXPERIMENTS.md` with any new runs.
8. Updated `outputs/latest-summary.md`.
9. A concise final report with:
   - local Gemma 3 4B average;
   - public leaderboard Gemma 3 4B average;
   - task-wise deltas;
   - what was fixed;
   - what remains not identical because of official Inspect AI vs lm-eval differences.

## Do not do yet

- Do not implement NFM-specific Intent-to-Recipe benchmark in this pass unless the user explicitly asks.
- Do not move to RAG-Ops evaluation yet.
- Do not refactor the whole repo structure.
- Do not remove the existing `otlite` result files.
- Do not claim exact GSMA leaderboard reproduction unless it is actually demonstrated.

## Final working definition

This repository should become:

> A reproducible LM-Evaluation-Harness based Open Telco baseline evaluator for NFM-LLM candidate models, with clear documentation of how close it is to the public GSMA leaderboard and where it intentionally differs.
