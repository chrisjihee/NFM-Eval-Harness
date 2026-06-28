#!/bin/bash
# 7-1. Clone LM-Evaluation-Harness (for Task Execution)
git clone https://github.com/EleutherAI/lm-evaluation-harness

# 7-2. Clone GSMA-Evals (for Task Implementation)
git clone https://github.com/gsma-labs/evals gsma-evals

# 8. Link HF cache and login to HF
shopt -s globstar
rm -f .cache_hf; ln -s ~/.cache/huggingface ./.cache_hf

source .venv/bin/activate
hf auth whoami
hf auth login
