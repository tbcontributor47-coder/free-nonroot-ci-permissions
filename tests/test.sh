#!/bin/bash
set -euo pipefail

# Install curl (needed to install uv)
apt-get update
apt-get install -y curl

# Install uv
curl -LsSf https://astral.sh/uv/0.9.5/install.sh | sh

# Load uv into PATH
source "$HOME/.local/bin/env"

# Safety check: ensure we are not running from /
if [ "$PWD" = "/" ]; then
    echo "Error: No working directory set."
    exit 1
fi

# Run pytest using uv
uvx \
  -p 3.13 \
  -w pytest==8.4.1 \
  -w pytest-json-ctrf==0.3.5 \
  pytest --ctrf /logs/verifier/ctrf.json /tests/test_outputs.py -rA

# Write reward file (REQUIRED by Harbor)
if [ $? -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
