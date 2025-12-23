#!/bin/bash
set -euo pipefail

# We start as the non-root user 'ciuser'
whoami | grep -q '^ciuser$'

# Fix permissions using group ownership (no chmod 777)
# Create a group for build access if it doesn't exist
if ! getent group buildgroup >/dev/null; then
  groupadd buildgroup
fi

# Add ciuser to the group
usermod -aG buildgroup ciuser
# Change group ownership of the build directory
chown -R root:buildgroup /app/build

# Grant group write permissions (not world-writable)
chmod -R g+rwX /app/build

# Ensure new files inherit group ownership
sudo chmod g+s /app/build

# Run the build script as ciuser
/app/build/build.sh

# Verify output was created by the build (not hardcoded)
test -f /app/build/output.txt
grep -qx 'BUILD_STATUS=SUCCESS' /app/build/output.txt
