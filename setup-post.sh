#!/bin/bash
# 7. Link HF cache and login to HF
shopt -s globstar
rm -f .cache_hf; ln -s ~/.cache/huggingface ./.cache_hf
hf auth login
hf auth whoami
