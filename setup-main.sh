#!/bin/bash
set -e
VENV_DIR=${VENV_DIR:-.venv}
CUDA_VERSION=${CUDA_VERSION:-128}
PYTHON_VERSION=${PYTHON_VERSION:-3.12}
echo -e "Starting environment setup with the following configuration:\n"
echo -e "VENV_DIR              : $VENV_DIR"
echo -e "CUDA_VERSION          : $CUDA_VERSION"
echo -e "PYTHON_VERSION        : $PYTHON_VERSION"
echo -e ""

TORCH_WHL_URL=${TORCH_WHL_URL:-https://download.pytorch.org/whl/cu${CUDA_VERSION}}
VLLM_RUNTIME_LIB_DIR="$PWD/${VENV_DIR}/lib/python${PYTHON_VERSION}/site-packages/nvidia/cu13/lib"
echo -e "TORCH_WHL_URL         : $TORCH_WHL_URL"
echo -e "VLLM_RUNTIME_LIB_DIR  : $VLLM_RUNTIME_LIB_DIR"


# 4. Create a new environment
t0=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] Creating new environment..."
    deactivate 2>/dev/null || true; rm -rf "${VENV_DIR}"; rm -rf *.egg-info;
    uv venv "${VENV_DIR}" --python "${PYTHON_VERSION}" --python-preference only-managed --clear
    source "${VENV_DIR}/bin/activate"
    uv pip list
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Created new environment (Elapsed: $((SECONDS - t0))s)"


# 5-0. Install build tools
t0=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] Installing build tools..."
    uv pip install -U cmake ninja wheel packaging setuptools setuptools_scm setuptools_rust
echo "[$(date +'%Y-%m-%d %H:%M:%S')] build tools installed (Elapsed: $((SECONDS - t0))s)"


# 5-1. Install the required packages: pyproject.toml
t0=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] Installing main project dependencies..."
    cat pyproject.toml
    uv pip install -U -e . \
    --extra-index-url "${TORCH_WHL_URL}" \
    --index-strategy unsafe-best-match
echo "[$(date +'%Y-%m-%d %H:%M:%S')] main project dependencies installed (Elapsed: $((SECONDS - t0))s)"


# 5-2. Configure runtime libraries: vllm
t0=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] Configuring vllm runtime libraries..."
    export LD_LIBRARY_PATH="${VLLM_RUNTIME_LIB_DIR}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
    cat >> "${VENV_DIR}/bin/activate" <<EOF

# Added by setup-main.sh for vLLM wheel runtime libraries.
_VLLM_RUNTIME_LIB_DIR="\$VIRTUAL_ENV/lib/python${PYTHON_VERSION}/site-packages/nvidia/cu13/lib"
if [[ -d "\$_VLLM_RUNTIME_LIB_DIR" ]]; then
    export LD_LIBRARY_PATH="\$_VLLM_RUNTIME_LIB_DIR\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
fi
unset _VLLM_RUNTIME_LIB_DIR
EOF
    echo -e "========================================"
    echo -e " * Tail of ${VENV_DIR}/bin/activate"
    echo -e "========================================"
    tail -n 11 ${VENV_DIR}/bin/activate
    echo -e "========================================"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] vllm runtime libraries configured (Elapsed: $((SECONDS - t0))s)"


# 6. Check the installed packages and their versions
t0=$SECONDS; echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] Checking installed packages and versions..."
source "${VENV_DIR}/bin/activate"
uv pip list > version-dep.txt
uv pip list | grep -E "torch|trl|transformer|accelerate|llm|deepspeed|attn|peft|bitsandbytes|huggingface|datasets|pandas|numpy|chris|prog"

echo -e "\nChecking runtime imports for essential packages..."
python - <<'PY'
import torch, torchaudio, torchvision
print("* torch         :", torch.__version__, " (cuda version:", torch.version.cuda, ")")
print("* torchaudio    :", torchaudio.__version__)
print("* torchvision   :", torchvision.__version__)
print("* cuda available:", "Yes" if torch.cuda.is_available() else "No")
if torch.cuda.is_available():
    print("  - cuda devices:", ', '.join([torch.cuda.get_device_name(i) for i in range(torch.cuda.device_count())]))
    print("  - cuda tensor :", torch.tensor([1.0], device="cuda"))

import trl
from trl import SFTTrainer
print("* trl           :", trl.__version__, "\t-> import trl.SFTTrainer [OK]")

import vllm
from vllm import LLM
print("* vllm          :", vllm.__version__, "\t-> import vllm.LLM [OK]")
PY
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Checked installed packages and versions (Elapsed: $((SECONDS - t0))s)"
