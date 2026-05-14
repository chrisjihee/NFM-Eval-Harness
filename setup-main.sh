#!/bin/bash
set -e

# 4. Create a new environment
t1=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] 4. Creating new environment..."
    deactivate 2>/dev/null || true; rm -rf .venv; rm -rf *.egg-info;
    uv venv .venv --python 3.12 --python-preference only-managed --clear
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 4. Created new environment (Elapsed: $((SECONDS - t1))s)"


# 5. Install the required packages
t1=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] 5. Installing required packages..."
    source .venv/bin/activate; uv pip list

# torch 설치
t0=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] Installing torch..."
    uv pip install -U cmake ninja wheel packaging setuptools setuptools_scm
    uv pip install torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu128
echo "[$(date +'%Y-%m-%d %H:%M:%S')] torch installed (Elapsed: $((SECONDS - t0))s)"

# vllm 설치
t0=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] Installing vllm..."
    uv pip install -U cmake ninja wheel packaging setuptools setuptools_scm
    MAX_JOBS=$(nproc) uv pip install vllm \
        --no-binary vllm \
        --no-build-isolation \
        --extra-index-url https://download.pytorch.org/whl/cu128 \
        --index-strategy unsafe-best-match
echo "[$(date +'%Y-%m-%d %H:%M:%S')] vllm installed (Elapsed: $((SECONDS - t0))s)"

# lm-eval 설치
t0=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] Installing lm-eval..."
    rm -rf lm-evaluation-harness
    git clone --depth 1 https://github.com/EleutherAI/lm-evaluation-harness
    uv pip install -U cmake ninja wheel packaging setuptools setuptools_scm
    uv pip install -e ./lm-evaluation-harness \
        --extra-index-url https://download.pytorch.org/whl/cu128 \
        --index-strategy unsafe-best-match
    uv pip install "lm_eval[hf]" "lm_eval[api]" "lm_eval[vllm]" \
        --extra-index-url https://download.pytorch.org/whl/cu128 \
        --index-strategy unsafe-best-match
echo "[$(date +'%Y-%m-%d %H:%M:%S')] lm-eval installed (Elapsed: $((SECONDS - t0))s)"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] 5. Installed required packages (Elapsed: $((SECONDS - t1))s)"


# 6. Check the installed packages and their versions
source .venv/bin/activate; uv pip list > version-dep.txt; uv pip list | grep -E "torch|llm|deepspeed|attn|peft|transformer|accelerate|huggingface|datasets|pandas|numpy|chris|prog"
python - <<'PY'
import sys
import torch, vllm

print("- torch:", torch.__version__)
print("- torch.version.cuda:", torch.version.cuda)
print("- cuda available:", torch.cuda.is_available())
print("- device count:", torch.cuda.device_count())
if torch.cuda.is_available():
    print("- device 0:", torch.cuda.get_device_name(0))
    print("- cuda tensor:", torch.tensor([1.0], device="cuda"))

print("- vllm:", vllm.__version__)
from vllm import LLM, SamplingParams
print("- import vllm.LLM OK")
PY
