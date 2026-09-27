#!/usr/bin/env bash
# copilot_exec.sh - Safe wrapper for programmatic Copilot CLI executions
set -euo pipefail

usage() {
  local exit_code="${1:-1}"
  cat <<EOF
Usage: $(basename "$0") [options] -- "PROMPT"

Options:
  --autopilot          Run in autopilot mode (automatically enables --yolo for hands-free autonomy)
  --max-continues N    Max autopilot continuations (positive integer, default: 5)
  --with-mcp           Enable read-only GitHub MCP tools (actions, log summaries, issue/PR read)
  --with-mcp-all       Enable ALL GitHub MCP server tools (*, includes write actions)
  --allow-git          Allow exact git inspection commands (status, diff, log, show without output redirection)
  --allow-gh           Allow read-only gh viewing commands (pr view, run list, run view)
  --allow-write        Allow file modifications (write tool)
  --yolo               Allow all tools, paths, and URLs
  --model MODEL        Specify model identifier (default: auto)
  --output FILE        Save final response text to FILE (atomic same-directory write)
  --stats FILE         Write usage statistics JSON to FILE
  -h, --help           Show this help message
EOF
  exit "$exit_code"
}

AUTOPILOT=false
MAX_CONTINUES=5
WITH_MCP_READONLY=false
WITH_MCP_ALL=false
ALLOW_GIT=false
ALLOW_GH=false
ALLOW_WRITE=false
YOLO=false
MODEL=""
OUTPUT_FILE=""
STATS_FILE=""
PROMPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --autopilot) AUTOPILOT=true; shift ;;
    --max-continues)
      [[ $# -lt 2 || -z "${2:-}" ]] && { echo "Error: --max-continues requires an integer argument." >&2; usage 1; }
      if ! [[ "$2" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: --max-continues must be a positive integer, got '$2'." >&2
        usage 1
      fi
      MAX_CONTINUES="$2"; shift 2 ;;
    --with-mcp) WITH_MCP_READONLY=true; shift ;;
    --with-mcp-all) WITH_MCP_ALL=true; shift ;;
    --allow-git) ALLOW_GIT=true; shift ;;
    --allow-gh) ALLOW_GH=true; shift ;;
    --allow-write) ALLOW_WRITE=true; shift ;;
    --yolo) YOLO=true; shift ;;
    --model)
      [[ $# -lt 2 || -z "${2:-}" ]] && { echo "Error: --model requires a model ID argument." >&2; usage 1; }
      MODEL="$2"; shift 2 ;;
    --output)
      [[ $# -lt 2 || -z "${2:-}" ]] && { echo "Error: --output requires a file path argument." >&2; usage 1; }
      OUTPUT_FILE="$2"; shift 2 ;;
    --stats)
      [[ $# -lt 2 || -z "${2:-}" ]] && { echo "Error: --stats requires a file path argument." >&2; usage 1; }
      STATS_FILE="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    --) shift; PROMPT="$*"; break ;;
    *) PROMPT="$*"; break ;;
  esac
done

if [[ -z "${PROMPT:-}" ]]; then
  echo "Error: Prompt cannot be empty." >&2
  usage 1
fi

CMD=(copilot)

# Autopilot requires full permissions to operate without user interruption
if [[ "$AUTOPILOT" == "true" ]]; then
  YOLO=true
  CMD+=(--autopilot --max-autopilot-continues "$MAX_CONTINUES")
fi

if [[ "$YOLO" == "true" ]]; then
  CMD+=(--yolo)
else
  if [[ "$ALLOW_GIT" == "true" ]]; then
    # Constrain git commands to exact safe read-only queries; deny all forms of output redirection
    CMD+=(--allow-tool='shell(git status)' \
          --allow-tool='shell(git status --porcelain)' \
          --allow-tool='shell(git diff)' \
          --allow-tool='shell(git diff HEAD)' \
          --allow-tool='shell(git diff --cached)' \
          --allow-tool='shell(git log -n 5)' \
          --allow-tool='shell(git log -n 10)' \
          --allow-tool='shell(git show)' \
          --allow-tool='shell(git show HEAD)' \
          --allow-tool='shell(git rev-parse HEAD)' \
          --allow-tool='shell(git ls-files)' \
          --deny-tool='shell(git diff --output*)' \
          --deny-tool='shell(git diff -o*)' \
          --deny-tool='shell(git log --output*)' \
          --deny-tool='shell(git log -o*)' \
          --deny-tool='shell(git show --output*)' \
          --deny-tool='shell(git show -o*)')
  fi
  if [[ "$ALLOW_GH" == "true" ]]; then
    CMD+=(--allow-tool='shell(gh pr view:*)' \
          --allow-tool='shell(gh run list:*)' \
          --allow-tool='shell(gh run view:*)')
  fi
  [[ "$ALLOW_WRITE" == "true" ]] && CMD+=(--allow-tool='write')
fi

if [[ "$WITH_MCP_ALL" == "true" ]]; then
  CMD+=(--add-github-mcp-tool "*")
  [[ "$YOLO" == "false" ]] && CMD+=(--allow-tool=github-mcp-server)
elif [[ "$WITH_MCP_READONLY" == "true" ]]; then
  CMD+=(--add-github-mcp-tool "actions_list" \
        --add-github-mcp-tool "actions_get" \
        --add-github-mcp-tool "summarize_job_log_failures" \
        --add-github-mcp-tool "summarize_run_log_failures" \
        --add-github-mcp-tool "issue_read" \
        --add-github-mcp-tool "pull_request_read" \
        --allow-tool='github-mcp-server(actions_list)' \
        --allow-tool='github-mcp-server(actions_get)' \
        --allow-tool='github-mcp-server(summarize_job_log_failures)' \
        --allow-tool='github-mcp-server(summarize_run_log_failures)' \
        --allow-tool='github-mcp-server(issue_read)' \
        --allow-tool='github-mcp-server(pull_request_read)')
fi

[[ -n "$MODEL" ]] && CMD+=(--model "$MODEL")
[[ -n "$STATS_FILE" ]] && CMD+=(--usage-output-file "$STATS_FILE")

CMD+=(-p "$PROMPT" -s --no-color --no-ask-user)

if [[ -n "$OUTPUT_FILE" ]]; then
  OUT_DIR="$(dirname "$OUTPUT_FILE")"
  TMP_OUT="$(mktemp -p "$OUT_DIR" .copilot_out.XXXXXX)"
  trap 'rm -f "$TMP_OUT"' EXIT
  "${CMD[@]}" > "$TMP_OUT"
  mv -f -- "$TMP_OUT" "$OUTPUT_FILE"
  trap - EXIT
else
  "${CMD[@]}"
fi
