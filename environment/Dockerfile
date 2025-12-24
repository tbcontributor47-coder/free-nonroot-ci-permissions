FROM ubuntu:22.04

# Create non-root user
RUN useradd -m -u 1001 ciuser

# Create logs directory with proper permissions for non-root user
RUN mkdir -p /logs/verifier && \
    chown -R ciuser:ciuser /logs

# Create application directory
WORKDIR /app

# Create build directory with incorrect permissions (intentional)
RUN mkdir -p /app/build && \
    chmod 755 /app/build && \
    chown root:root /app/build

# Add a failing build script
RUN printf '#!/bin/bash\nset -e\n\necho "BUILD_STATUS=SUCCESS" > /app/build/output.txt\n' \
    > /app/build/build.sh && \
    chmod 755 /app/build/build.sh && \
    chown root:root /app/build/build.sh

# Switch to non-root user
USER ciuser

# Add entrypoint that ensures /logs/verifier exists with correct permissions
COPY --chown=ciuser:ciuser entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Default command does nothing; agent must run build explicitly
CMD ["bash"]
