#!/bin/bash
# Entrypoint that ensures /logs/verifier/ exists and is writable

# If /logs/ exists (Harbor mounts it), ensure verifier subdirectory exists
if [ -d /logs ]; then
  mkdir -p /logs/verifier 2>/dev/null || {
    # If mkdir fails (permission denied), try with sudo
    if command -v sudo &>/dev/null; then
      sudo mkdir -p /logs/verifier
      sudo chown -R $(id -u):$(id -g) /logs/verifier
    fi
  }
  
  # Ensure it's writable
  if [ ! -w /logs/verifier ] && command -v sudo &>/dev/null; then
    sudo chown -R $(id -u):$(id -g) /logs/verifier
  fi
fi

# Execute the command passed to the container
exec "$@"
