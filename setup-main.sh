#!/bin/bash
# 4. Create a new environment
t1=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] 4. Creating new environment..."
deactivate 2>/dev/null || true; rm -rf .venv; rm -rf *.egg-info;
uv venv .venv --python 3.12 --python-preference only-managed --clear
echo "[$(date +'%Y-%m-%d %H:%M:%S')] 4. Created new environment (Elapsed: $((SECONDS - t1))s)"

# 5. Install the required packages
t1=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] 5. Installing standard required packages..."
source .venv/bin/activate; uv pip list

uv pip install cmake ninja wheel packaging setuptools_scm

rm -rf lm-evaluation-harness
git clone --depth 1 https://github.com/EleutherAI/lm-evaluation-harness

# CUDA 12.8용 torch를 먼저 고정
uv pip install torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cu128

# lm-eval 설치
uv pip install -e ./lm-evaluation-harness \
  --extra-index-url https://download.pytorch.org/whl/cu128 \
  --index-strategy unsafe-best-match

uv pip install "lm_eval[hf]" "lm_eval[api]" \
  --extra-index-url https://download.pytorch.org/whl/cu128 \
  --index-strategy unsafe-best-match

# uv pip install "lm_eval[vllm]"


python - <<'PY'
import torch
print("- torch:", torch.__version__)
print("- torch.version.cuda:", torch.version.cuda)
print("- cuda available:", torch.cuda.is_available())
print("- device count:", torch.cuda.device_count())
if torch.cuda.is_available():
    print("- device 0:", torch.cuda.get_device_name(0))
    print("cuda tensor:", torch.tensor([1.0], device="cuda"))
PY

uv pip list > version-dep.txt; uv pip list | grep -E "torch|llm|deepspeed|attn|peft|transformer|accelerate|huggingface|datasets|pandas|numpy|chris|prog"
