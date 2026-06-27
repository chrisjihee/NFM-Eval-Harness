# Environment notes

Last updated: 2026-06-27

## Purpose

This file records known environment assumptions for running `NFM-Eval-Harness`.

> **Task name 정책 (rename).** The run scripts default to the GSMA-compatible
> groups `open_telco_otlite_gsma` / `open_telco_otfull_gsma` (just omit `TASKS`;
> unweighted). The legacy lm-eval/loglikelihood baseline is preserved as
> `open_telco_{otlite,otfull}_lm_eval_baseline` (diagnostic). The bare group
> names `open_telco_otlite` / `open_telco_otfull` are **not runnable** — the run
> scripts fail fast and point to the new names. `*_mcgen` stays diagnostic
> (unchanged). The commands below omit `TASKS`, so they run the `*_gsma` default.

## Current intended environment

The repo was developed for GPU-server execution.

Expected stack:

- Linux GPU server.
- Python managed through `uv`.
- Local virtual environment: `.venv`.
- LM-Evaluation-Harness command: `lm_eval`.
- Main model backends:
  - Hugging Face backend: `--model hf`.
  - vLLM backend: `--model vllm`.
- Main datasets:
  - `GSMA/ot-lite`.
  - `GSMA/ot-full`.
  - `GSMA/leaderboard` for public score comparison.

## Setup scripts

Run from repository root:

```bash
./setup-pre.sh
./setup-main.sh
./setup-post.sh
```

`setup-main.sh` creates `.venv`, installs project dependencies, configures vLLM runtime libraries, and writes package versions to `version-dep.txt`.

## LM-Evaluation-Harness pin

The vendored clone `lm-evaluation-harness/` is pinned to:

```text
sha 97a5e2c7  (git describe: v0.4.12-12-g97a5e2c7)
```

Install it editable, without dependencies, so the hard-pinned torch / vllm / transformers
versions in `pyproject.toml` are not overwritten:

```bash
uv pip install -e ./lm-evaluation-harness --no-deps
```

Note: the current `.venv` may not have `lm_eval` installed (verified absent during this
documentation pass). Install it before any run:

```bash
.venv/bin/python -c "import lm_eval" || uv pip install -e ./lm-evaluation-harness --no-deps
```

## Important dependency notes

`pyproject.toml` currently pins a modern and heavy stack, including:

- Python `>=3.12`.
- PyTorch CUDA 12.8 wheel family.
- Transformers 5.x.
- vLLM 0.23.x.
- TRL/PEFT/bitsandbytes.

This stack may not reproduce on every server. If a target server cannot support the current vLLM/CUDA combination, preserve the existing setup and document the failure before changing pins.

## vLLM / CUDA note

`setup-main.sh` contains CUDA forward-compatibility handling for newer vLLM wheels. This was added because vLLM import success does not guarantee that `LLM.generate()` works.

The setup checks actual vLLM generation using `check_vllm_runtime.py` unless disabled.

If vLLM fails, first inspect:

```bash
version-vllm-check.log
```

## Hugging Face token / gated models

Some models may require Hugging Face authentication. Before running Gemma or Llama models, verify:

```bash
huggingface-cli whoami
```

or ensure the environment has appropriate `HF_TOKEN` access.

## Basic run commands

These are full GPU runs, so each carries the explicit `CONFIRM_FULL_RUN=1` guard. For a
quick check, use `LIMIT=5` instead of `CONFIRM_FULL_RUN=1` (see "Recommended smoke tests").
Omitting `TASKS` runs the default `*_gsma` group. To run the legacy lm-eval baseline,
set `TASKS=open_telco_otlite_lm_eval_baseline` (or `..._otfull_lm_eval_baseline`).

`ot-lite_gsma` (default) with HF backend:

```bash
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

`ot-full_gsma` (default) with HF backend:

```bash
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

`ot-lite_gsma` (default) with vLLM backend:

```bash
CONFIRM_FULL_RUN=1 BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

## Recommended smoke tests

Always start with a bounded smoke before any full run. The runner enforces a bound via the
`LIMIT` guard, so a copy-paste cannot accidentally launch a full GPU run:

```bash
LIMIT=5 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

A full run requires an explicit confirmation flag:

```bash
CONFIRM_FULL_RUN=1 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

If you must invoke `lm_eval` directly for a single task, always pass `--limit`:

```bash
lm_eval \
  --model hf \
  --model_args pretrained=google/gemma-3-4b-it \
  --include_path ./open_telco_lm_eval/tasks \
  --tasks open_telco_telemath_gsma \
  --limit 5 \
  --device cuda:0 \
  --batch_size auto \
  --apply_chat_template
```

## TeleTables table content

For fairer TeleTables evaluation, original table files may be needed.

Set:

```bash
export TELETABLES_ROOT=/path/to/extracted/TeleTables/tables
```

Expected tree pattern:

```text
$TELETABLES_ROOT/<document_id>/<table_id>/table.md
$TELETABLES_ROOT/<document_id>/<table_id>/table.html
$TELETABLES_ROOT/<document_id>/<table_id>/table.json
```

The current parser searches those paths and injects table content if present.

## Recording results

After any meaningful run, update:

- `EXPERIMENTS.md`
- `PROGRESS.md`
- `outputs/latest-summary.md`

Do not commit huge raw logs, model caches, checkpoints, or downloaded datasets.
