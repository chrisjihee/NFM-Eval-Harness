#!/usr/bin/env bash
set -euo pipefail

find . \
  \( -type d -name '.*' ! -name '.' -prune \) -o \
  \( -name '.DS_Store' -o -name '._*' \) -prune -o \
  -print
