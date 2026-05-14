#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "${ROOT_DIR}/.venv" ]]; then
  echo "Missing virtual environment at ${ROOT_DIR}/.venv" >&2
  exit 1
fi

source "${ROOT_DIR}/.venv/bin/activate"

MODEL_NAME="${MODEL_NAME:-meta-llama/Llama-3.2-1B-Instruct}"
DEVICE="${DEVICE:-cuda:0}"
BATCH_SIZE="${BATCH_SIZE:-auto}"
OUTPUT_PATH="${OUTPUT_PATH:-${ROOT_DIR}/results/open_telco_otlite}"
TASKS="${TASKS:-open_telco_otlite}"

lm_eval \
  --model hf \
  --model_args "pretrained=${MODEL_NAME}" \
  --include_path "${ROOT_DIR}/open_telco_lm_eval/tasks" \
  --tasks "${TASKS}" \
  --device "${DEVICE}" \
  --batch_size "${BATCH_SIZE}" \
  --apply_chat_template \
  --output_path "${OUTPUT_PATH}"
