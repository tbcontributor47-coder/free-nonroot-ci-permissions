#!/bin/bash
set -u -o pipefail

if ! command -v curl &>/dev/null; then
  echo "ERROR: curl is required but not installed"
  echo 0 > /logs/verifier/reward.txt 2>/dev/null || true
  exit 0
fi

# Install uv
curl -LsSf https://astral.sh/uv/0.9.5/install.sh | sh

# Load uv into PATH
source "$HOME/.local/bin/env"

# Safety check: ensure we are not running from /
if [ "$PWD" = "/" ]; then
    echo "Error: No working directory set."
    echo 0 > /logs/verifier/reward.txt 2>/dev/null || true
    exit 0
fi

# Run pytest using uv
set +e
uvx \
  -p 3.13 \
  -w pytest==8.4.1 \
  -w pytest-json-ctrf==0.3.5 \
  pytest -o cache_dir=/tmp/pytest_cache --ctrf /logs/verifier/ctrf.json /tests/test_outputs.py -rA
pytest_exit=$?
set -e

if [ $pytest_exit -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi

# Always exit 0 so Harbor consumes the reward instead of raising an exception
exit 0