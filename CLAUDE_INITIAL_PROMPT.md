# Initial prompt to paste into a new Claude Code chat

Use the following prompt when starting a fresh Claude Code session in a cloned `NFM-Eval-Harness` working directory.

---

You are Claude Code working inside the cloned repository `NFM-Eval-Harness`.

Your task is to finish the first practical pass of the NFM-LLM evaluation harness for the ETRI NFM project.

Please begin by reading these files in order:

1. `CLAUDE.md`
2. `HANDOFF_NFM_EVAL_HARNESS.md`
3. `README.md`
4. `PLAN.md`
5. `PROGRESS.md`
6. `EXPERIMENTS.md`
7. `outputs/latest-summary.md`
8. `open_telco_lm_eval/README.md`
9. `AGENTS.md`

Then run:

```bash
git status
```

Do not modify files until you have summarized the current repo status and your plan.

## Background

This repository is for the ETRI Language Intelligence Lab's NFM-LLM evaluation work. It uses LM-Evaluation-Harness to run GSMA Open Telco AI benchmark tasks. It is not intended to exactly duplicate the official GSMA Inspect AI evaluation stack, but it should be close enough to the public leaderboard to be credible for model baseline comparison.

The public GSMA leaderboard currently lists:

```text
model: gemma3-4b
provider: Google
rank: 78
average: 0.397
```

The current local tracked run is:

```text
model: google/gemma-3-4b-it
backend: hf
task group: open_telco_otlite
average acc: 0.3718
```

The average gap is modest, but task-level differences are large. Your main job is to make the implementation and documentation strong enough to explain or reduce this mismatch.

## Immediate objectives

1. Inspect current implementation of `ot-lite` and `ot-full` task packs.
2. Verify task loading and identify whether all 7 tasks are implemented cleanly.
3. Add missing documentation:
   - `TASK_MANIFEST.md`
   - `REPRODUCTION_NOTES.md`
   - update `PROGRESS.md`, `EXPERIMENTS.md`, `outputs/latest-summary.md` as needed.
4. Add a comparison script, preferably `scripts/compare_gsma_leaderboard.py`, that compares local lm-eval JSON results with the public `GSMA/leaderboard` row for `gemma3-4b`.
5. Add a lightweight smoke-test path or script for task loading / small-limit evaluation.
6. Investigate why the local result differs from the leaderboard, especially:
   - `ot-lite` vs `ot-full` mismatch;
   - official Inspect AI stack vs lm-eval implementation;
   - model name mismatch: `gemma3-4b` vs `google/gemma-3-4b-it`;
   - chat template use;
   - multiple-choice scoring method;
   - generation parser strictness;
   - `until: ["\n"]` and `max_gen_toks` settings;
   - HF max context length / truncation warnings;
   - TeleTables missing table content unless `TELETABLES_ROOT` is set.
7. If GPU is available, re-run:

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

If vLLM is available, also test:

```bash
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

If GPU is not available, do not fake results. Implement scripts/docs and provide exact commands for the user to run.

## Constraints

- Keep this repo LM-Evaluation-Harness based.
- Do not replace the project with Inspect AI.
- Do not refactor the whole repository.
- Do not delete existing results.
- Do not commit huge logs, model caches, checkpoints, or generated artifacts.
- Do not claim exact leaderboard reproduction unless it is actually demonstrated.
- Be explicit about mismatches and known limitations.

## Desired output of this pass

At the end, provide a concise report covering:

1. what you changed;
2. which tasks are implemented;
3. which commands were run;
4. local Gemma 3 4B result;
5. public leaderboard comparison;
6. task-wise deltas;
7. what mismatch causes were fixed;
8. what remains unresolved;
9. what the user should run next if full GPU evaluation was not possible.

Start now by reading the required files and summarizing your plan before editing.
