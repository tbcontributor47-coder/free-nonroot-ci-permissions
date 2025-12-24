FROM ubuntu:22.04

# Keep the environment minimal and avoid test-only tools.
# The verifier installs its own dependencies; we only include what's required
# to fetch and run the verifier bootstrap without curl.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates python3 && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1001 ciuser

# Create application directory
WORKDIR /app

# Create build directory with secure permissions:
# - owned by root
# - writable by group 'ciuser'
# - not world-writable
# - setgid so files created inside inherit group 'ciuser'
RUN mkdir -p /app/build && \
    chown root:ciuser /app/build && \
    chmod 2775 /app/build

# Add a failing build script
RUN printf '#!/bin/bash\nset -e\n\necho "BUILD_STATUS=SUCCESS" > /app/build/output.txt\n' \
    > /app/build/build.sh && \
    chmod 755 /app/build/build.sh && \
    chown root:root /app/build/build.sh

# Switch to non-root user
USER ciuser

# Default command does nothing; agent must run build explicitly
CMD ["bash"]
