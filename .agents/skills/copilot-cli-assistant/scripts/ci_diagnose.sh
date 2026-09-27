#!/usr/bin/env bash
# ci_diagnose.sh - Offload CI workflow log analysis to Copilot CLI with least privilege
set -euo pipefail

REPO="${1:-kud3n013/archrepo}"
WORKFLOW="${2:-build.yml}"

echo ">>> Inspecting recent CI failure for ${REPO} (${WORKFLOW}) via Copilot CLI..."

PROMPT="Use the GitHub MCP server tools (actions_list, summarize_run_log_failures, or summarize_job_log_failures) to diagnose the latest failed workflow run in repository '${REPO}' for workflow '${WORKFLOW}'.

Provide a concise report:
1. Run ID, Commit SHA, and Timestamp
2. Failing Package or Job Name
3. Root Cause Summary (synthesized from the failure logs)
4. Recommended Fix for PKGBUILD, upstream.json, or workflow script
Do NOT dump raw terminal logs."

# Apply principle of least privilege: only enable and authorize read-only Actions tools
# to prevent untrusted log content from triggering side-effecting tools.
copilot -p "$PROMPT" \
  --add-github-mcp-tool "actions_list" \
  --add-github-mcp-tool "actions_get" \
  --add-github-mcp-tool "summarize_job_log_failures" \
  --add-github-mcp-tool "summarize_run_log_failures" \
  --allow-tool='github-mcp-server(actions_list)' \
  --allow-tool='github-mcp-server(actions_get)' \
  --allow-tool='github-mcp-server(summarize_job_log_failures)' \
  --allow-tool='github-mcp-server(summarize_run_log_failures)' \
  --no-ask-user \
  -s --no-color
