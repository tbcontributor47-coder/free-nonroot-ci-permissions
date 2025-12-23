# Fix Non-Root CI Build Permissions

A CI build fails because a non-root user does not have permission
to write build artifacts.

Your task is to fix the permissions issue so the build succeeds
when run as a non-root user.

---

## Background

Inside the container:

- A non-root user named `ciuser` is used.
- A build script exists at `/app/build/build.sh`.
- The build script attempts to write a file to `/app/build/output.txt`.
- The directory `/app/build` is currently owned by root and is not
  writable by `ciuser`.

As a result, running the build script fails.

---

## Requirements

You must modify the environment so that:

1. The build script at `/app/build/build.sh` runs successfully
   **as the non-root user `ciuser`**.
2. The build produces the file `/app/build/output.txt`.
3. The file `/app/build/output.txt` contains exactly:

```
BUILD_STATUS=SUCCESS
```
4. The permissions fix must be done using **correct ownership or group
permissions**, not by making the directory world-writable.

---

## Constraints

The following actions are **not allowed**:

- Do **not** run the build as root.
- Do **not** change the USER to root.
- Do **not** use `chmod 777` on any file or directory.
- Do **not** modify the contents or logic of `/app/build/build.sh`.
- Modifying `/app/build/build.sh` is unnecessary and will not help complete the task.

---

## Expected Outcome

After your fix:

- Running `/app/build/build.sh` as `ciuser` succeeds.
- `/app/build/output.txt` exists and is readable.
- The output file is owned by a non-root user.
- Permissions are restrictive and secure (not world-writable).

Only the permissions issue should be fixed.
No other behavior should be modified.
