#!/bin/bash
# Entrypoint that ensures /logs/verifier/ exists and is writable

# If /logs/ exists (Harbor mounts it), ensure verifier subdirectory exists
if [ -d /logs ]; then
  mkdir -p /logs/verifier 2>/dev/null || {
    # If mkdir fails (permission denied), try with sudo
    if command -v sudo &>/dev/null; then
      sudo mkdir -p /logs/verifier
    fi
  }
  
  # Make it world-writable so both container user and Harbor host process can write
  chmod 777 /logs/verifier 2>/dev/null || {
    if command -v sudo &>/dev/null; then
      sudo chmod 777 /logs/verifier
    fi
  }
fi

# Execute the command passed to the container
exec "$@"
