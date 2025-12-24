#!/bin/bash
set -euo pipefail

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

# Ensure /logs/verifier/ exists and is writable
if [ ! -d /logs/verifier ]; then
  if command -v sudo &>/dev/null; then
    sudo mkdir -p /logs/verifier
    sudo chown -R $(id -u):$(id -g) /logs/verifier
  else
    mkdir -p /logs/verifier
  fi
fi

# Verify we can write to /logs/verifier/
if [ ! -w /logs/verifier ]; then
  if command -v sudo &>/dev/null; then
    sudo chown -R $(id -u):$(id -g) /logs/verifier
  else
    echo "Error: /logs/verifier is not writable and sudo is not available"
    exit 1
  fi
fi

# Run pytest using uv
uvx \
  -p 3.13 \
  -w pytest==8.4.1 \
  -w pytest-json-ctrf==0.3.5 \
  pytest --ctrf /logs/verifier/ctrf.json /tests/test_outputs.py -rA

# Write reward file
if [ $? -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi