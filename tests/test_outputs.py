"""
Tests for the 'Fix Non-Root CI Build Permissions' task.

These tests verify observable behavior:
- The build script is executed
- The output file is created by the build
- The build runs as a non-root user (ciuser)
- Permissions are secure (not world-writable)
- Output is not pre-created or hardcoded
"""

from pathlib import Path
import os
import stat
import pwd

OUTPUT_FILE = Path("/app/build/output.txt")
BUILD_DIR = Path("/app/build")
BUILD_SCRIPT = Path("/app/build/build.sh")


def test_build_script_exists_and_executable():
    """Verify the build script exists and is executable."""
    assert BUILD_SCRIPT.exists(), "build.sh is missing"
    assert os.access(BUILD_SCRIPT, os.X_OK), "build.sh is not executable"


def test_build_executes_and_creates_output_as_ciuser():
    """
    Execute the build script and verify it creates output
    as user `ciuser` with secure permissions.
    """
    # Prevent pre-baked output
    if OUTPUT_FILE.exists():
        OUTPUT_FILE.unlink()

    # Execute the build
    exit_code = os.system("/app/build/build.sh")
    assert exit_code == 0, "build.sh failed to execute"

    # Output must be created by the build
    assert OUTPUT_FILE.exists(), "output.txt was not created"

    # Exact expected content
    content = OUTPUT_FILE.read_text().strip()
    assert content == "BUILD_STATUS=SUCCESS"

    # Output must be owned by ciuser
    st = OUTPUT_FILE.stat()
    owner = pwd.getpwuid(st.st_uid).pw_name
    assert owner == "ciuser", f"output.txt owned by {owner}, expected ciuser"

    # Output must not be world-writable
    assert not (st.st_mode & stat.S_IWOTH), "output.txt is world-writable"


def test_build_directory_not_world_writable():
    """Verify the build directory is not world-writable."""
    mode = BUILD_DIR.stat().st_mode
    assert not (mode & stat.S_IWOTH), "build directory is world-writable"
