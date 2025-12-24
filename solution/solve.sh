#!/bin/bash
set -euo pipefail

# We start as the non-root user 'ciuser'
whoami | grep -q '^ciuser$'

# Run the build script as ciuser
rm -f /app/build/output.txt
/app/build/build.sh

# Verify output was created by the build (not hardcoded)
test -f /app/build/output.txt
grep -qx 'BUILD_STATUS=SUCCESS' /app/build/output.txt
