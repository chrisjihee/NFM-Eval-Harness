#!/bin/bash
# 7. Link HF cache and login to HF
shopt -s globstar
rm -f .cache_hf; ln -s ~/.cache/huggingface ./.cache_hf
bash reset_cache.sh
#hf auth login
hf auth whoami
