#!/usr/bin/env bash
# code_review.sh - Offload git diff code review to Copilot CLI with zero-permission snapshotting
set -euo pipefail

TARGET="${1:-HEAD}"

# Validate target ref
if ! git rev-parse --verify "${TARGET}^{commit}" >/dev/null 2>&1; then
  echo "Error: Target ref '${TARGET}' is not a valid git commit." >&2
  exit 1
fi

echo ">>> Generating repository diff snapshot against ${TARGET} (including untracked files)..."

DIFF_SNAPSHOT="$(mktemp -p "/tmp" copilot_diff.XXXXXX)"
trap 'rm -f "$DIFF_SNAPSHOT"' EXIT

{
  echo "==================== DIFF AGAINST ${TARGET} ===================="
  git diff "$TARGET"

  echo "==================== UNTRACKED FILES SNAPSHOT ===================="
  while IFS= read -r -d '' f; do
    if [[ -L "$f" ]]; then
      # Handle symlinks safely without following targets outside the repo
      echo "--- Untracked Symlink: $f -> $(readlink "$f") ---"
    elif [[ -f "$f" ]]; then
      echo "--- Untracked File: $f ---"
      # git diff --no-index returns 1 when differences are found, 0 when identical
      git diff --no-index --text -- /dev/null "$f" || [ $? -eq 1 ]
    fi
  done < <(git ls-files -z --others --exclude-standard)
} > "$DIFF_SNAPSHOT"

# Fail-closed guard against oversized diffs
MAX_SNAPSHOT_BYTES=150000
SNAPSHOT_SIZE=$(wc -c < "$DIFF_SNAPSHOT")
if [[ "$SNAPSHOT_SIZE" -gt "$MAX_SNAPSHOT_BYTES" ]]; then
  echo "Error: Diff snapshot size (${SNAPSHOT_SIZE} bytes) exceeds limit (${MAX_SNAPSHOT_BYTES} bytes)." >&2
  echo "Please narrow the review scope or review specific directories to avoid incomplete audits." >&2
  exit 1
fi

echo ">>> Requesting agentic code review from Copilot CLI..."

PROMPT="Perform a rigorous agentic code review of the following repository changes (diff against ${TARGET} plus untracked files).

Verify:
1. Arch Linux PKGBUILD guidelines (valid variables, correct pkgrel reset, .SRCINFO synchronization).
2. Shell script safety in .sh files (proper quoting, set -euo pipefail, trap handlers, ShellCheck compliance).
3. GitHub Actions workflow syntax and security (untrusted input in run steps, permissions block).
4. Edge cases, potential regressions, or missing files.

Format output with:
- Summary of review
- Critical findings (with file:line and proposed fix)
- Minor suggestions
- Approval verdict (APPROVE / CHANGES_REQUESTED)

--- BEGIN REPOSITORY CHANGES ---
$(cat "$DIFF_SNAPSHOT")
--- END REPOSITORY CHANGES ---"

# Explicitly forbid all tool executions and URL access to guarantee a strict text-only analysis sandbox
copilot -p "$PROMPT" \
  --deny-tool='shell' \
  --deny-tool='write' \
  --deny-tool='github-mcp-server' \
  --deny-url='*' \
  --no-ask-user \
  -s --no-color
