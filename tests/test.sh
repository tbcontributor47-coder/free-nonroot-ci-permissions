#!/bin/bash
set -euo pipefail

# Create logs directory in a writable location (not /logs)
mkdir -p "$HOME/logs/verifier"

# Install curl (needed to install uv) - use sudo if available, otherwise skip
if command -v sudo &>/dev/null; then
  sudo apt-get update
  sudo apt-get install -y curl
elif [ -w /var/lib/apt/lists ]; then
  apt-get update
  apt-get install -y curl
else
  echo "Warning: Cannot install curl via apt; assuming it's already installed"
fi

# Install uv
curl -LsSf https://astral.sh/uv/0.9.5/install.sh | sh

# Load uv into PATH
source "$HOME/.local/bin/env"

# Safety check: ensure we are not running from /
if [ "$PWD" = "/" ]; then
    echo "Error: No working directory set."
    exit 1
fi

# Run pytest using uv (write ctrf to writable location)
uvx \
  -p 3.13 \
  -w pytest==8.4.1 \
  -w pytest-json-ctrf==0.3.5 \
  pytest --ctrf "$HOME/logs/verifier/ctrf.json" /tests/test_outputs.py -rA

# Write reward file to writable location
if [ $? -eq 0 ]; then
  echo 1 > "$HOME/logs/verifier/reward.txt"
else
  echo 0 > "$HOME/logs/verifier/reward.txt
fi

# Copy reward to Harbor's expected location if writable
if [ -d /logs/verifier ] && [ -w /logs/verifier ]; then
  cp "$HOME/logs/verifier/reward.txt" /logs/verifier/reward.txt 2>/dev/null || true
  cp "$HOME/logs/verifier/ctrf.json" /logs/verifier/ctrf.json 2>/dev/null || true
fi