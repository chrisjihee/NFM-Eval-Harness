# Environment notes

Last updated: 2026-06-25

## Purpose

This file records known environment assumptions for running `NFM-Eval-Harness`.

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

`ot-lite` with HF backend:

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

`ot-full` with HF backend:

```bash
MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otfull.sh
```

`ot-lite` with vLLM backend:

```bash
BACKEND=vllm VLLM_VISIBLE_DEVICES=0 MODEL_NAME=google/gemma-3-4b-it ./run_open_telco_otlite.sh
```

## Recommended smoke tests

Start with a single task and small limit before full runs:

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

Then test one generation-heavy task:

```bash
lm_eval \
  --model hf \
  --model_args pretrained=google/gemma-3-4b-it \
  --include_path ./open_telco_lm_eval/tasks \
  --tasks open_telco_telemath \
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
