#!/bin/bash
set -e

# Run this script from the project root.
shopt -s globstar nullglob dotglob

echo "[CLEAN] deactivate current venv"
deactivate 2>/dev/null || true

echo "[CLEAN] uv cache"
if command -v uv >/dev/null 2>&1; then
  uv cache clean || true
fi

echo "[CLEAN] project virtualenv and editable package sources"
rm -rf .venv
rm -rf package-src

echo "[CLEAN] Python/package build artifacts"
rm -rf build
rm -rf dist
rm -rf .eggs
rm -rf *.egg-info
rm -rf *.dist-info

echo "[CLEAN] Python caches"
rm -rf **/__pycache__
rm -rf **/.pytest_cache
rm -rf **/.mypy_cache
rm -rf **/.ruff_cache
rm -rf **/*.pyc
rm -rf **/*.pyo

echo "[CLEAN] lock/cache files in project"
rm -rf **/*.lock
rm -rf **/*.cache
rm -rf **/cache-*.arrow

echo "[CLEAN] project json cache directories"
rm -rf **/json

echo "[CLEAN] Hugging Face local cache under .cache_hf"
rm -rf .cache_hf/**/json
rm -rf .cache_hf/**/*lock
rm -rf .cache_hf/**/*.lock
rm -rf .cache_hf/**/.*.lock
rm -rf .cache_hf/**/.locks
rm -rf .cache_hf/**/mse
rm -rf .cache_hf/xet
rm -rf .cache_hf/modules
rm -rf .cache_hf/datasets

echo "[CLEAN] compiled extension caches"
rm -rf ~/.cache/torch_extensions
rm -rf ~/.cache/ninja
rm -rf ~/.cache/pip
rm -rf ~/.cache/vllm

echo "[DONE] reset complete"
