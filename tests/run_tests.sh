#!/bin/bash
set -euo pipefail

# This wrapper ensures /logs/verifier exists and is writable before Harbor runs the actual test.sh

# Ensure /logs/verifier/ exists and is writable
if [ ! -d /logs/verifier ]; then
  if command -v sudo &>/dev/null; then
    sudo mkdir -p /logs/verifier
    sudo chown -R $(id -u):$(id -g) /logs/verifier
  else
    mkdir -p /logs/verifier 2>/dev/null || true
  fi
fi

# Verify we can write to /logs/verifier/
if [ ! -w /logs/verifier ]; then
  if command -v sudo &>/dev/null; then
    sudo chown -R $(id -u):$(id -g) /logs/verifier
  fi
fi

# Now run the actual test script
exec /tests/test.sh
