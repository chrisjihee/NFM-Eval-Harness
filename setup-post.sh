#!/bin/bash
# 7. Clone LM-Evaluation-Harness
git clone https://github.com/EleutherAI/lm-evaluation-harness

# 8. Link HF cache and login to HF
shopt -s globstar
rm -f .cache_hf; ln -s ~/.cache/huggingface ./.cache_hf

source .venv/bin/activate
hf auth whoami
hf auth login
