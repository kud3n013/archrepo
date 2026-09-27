# Copilot CLI Tools & Permissions Reference

This reference documents the native tools, GitHub MCP server tools, and permission flags available in GitHub Copilot CLI (v1.0.88+).

---

## 1. Permission System & Syntax

Copilot CLI enforces permission boundaries around tools, paths, and URLs.

### Permission Flags

| Flag | Purpose | Example |
| :--- | :--- | :--- |
| `--allow-tool <tool>` | Pre-approves tool execution without prompting | `--allow-tool='shell(git:*)'` |
| `--deny-tool <tool>` | Explicitly blocks tool (takes precedence over allow) | `--deny-tool='shell(git push)'` |
| `--available-tools <tools>` | Exposes ONLY specified tools to the model | `--available-tools functions.rg functions.glob` |
| `--excluded-tools <tools>` | Hides specified tools from the model | `--excluded-tools functions.task` |
| `--allow-all-tools` | Pre-approves all tool executions | `--allow-all-tools` |
| `--allow-url <url>` | Allows access to specific domains or URLs | `--allow-url=github.com` |
| `--deny-url <url>` | Blocks access to specific domains/URLs | `--deny-url=malicious.com` |
| `--allow-all-urls` | Allows network access to all URLs | `--allow-all-urls` |
| `--allow-all-paths` | Disables directory path restriction | `--allow-all-paths` |
| `--allow-all` / `--yolo` | Shortcut for `--allow-all-tools --allow-all-paths --allow-all-urls` | `--yolo` |

### Tool Kind Patterns for `--allow-tool` & `--deny-tool`

1. **Shell commands**: `shell(command:*?)`
   - Exact match: `--allow-tool='shell(git status)'`
   - Subcommand prefix wildcard: `--allow-tool='shell(git:*)'`, `--allow-tool='shell(gh:*)'`, `--allow-tool='shell(makepkg:*)'`
   - All shell commands: `--allow-tool=shell`

2. **File modifications**: `write(path?)`
   - Specific file path: `--allow-tool='write(packages/beeper/PKGBUILD)'`
   - Relative trailing match: `--allow-tool='write(.SRCINFO)'`
   - All file writes: `--allow-tool=write`

3. **MCP Server tools**: `<server-name>(tool-name?)`
   - Specific tool: `--allow-tool='github-mcp-server(create_pull_request)'`
   - All tools from server: `--allow-tool=github-mcp-server`

4. **URL requests**: `url(domain-or-url?)`
   - Specific domain: `--allow-tool='url(https://api.github.com)'` or `--allow-tool='url(*.github.com)'`

---

## 2. Native Tools

| Tool Identifier | Description | Best Use Case |
| :--- | :--- | :--- |
| `functions.rg` | Fast regex search using ripgrep | Code exploration across entire repo |
| `functions.glob` | File pattern search | Locating PKGBUILDs, scripts, manifests |
| `functions.apply_patch` | Applies unified diff/patch to files | Targeted file modifications |
| `functions.task` | Launches an autonomous subagent | Delegating subtasks within Copilot |
| `functions.read_agent` | Reads subagent status and results | Monitoring spawned subagents |
| `functions.list_agents` | Lists visible subagents | Multi-agent coordination |
| `functions.write_agent` | Sends message to subagent | Steering subagents |
| `multi_tool_use.parallel` | Executes parallel tool calls | High-throughput queries |
| `shell(...)` | Executes terminal commands | Git, gh, build, test, makepkg |
| `write(...)` | File creation and modification | Editing codebase files |

---

## 3. GitHub MCP Server Tools

Copilot CLI includes a built-in GitHub MCP server. By default, a small subset is active. Use `--add-github-mcp-tool "*"` to enable all tools, or specify individual tools.

### Actions & CI
- `github-mcp-server-actions_list`: List repository workflows, runs, jobs, and artifacts.
- `github-mcp-server-actions_get`: Get details for runs, jobs, logs URLs.
- `github-mcp-server-actions_run_trigger`: Rerun, trigger, or cancel workflow runs.
- `github-mcp-server-summarize_job_log_failures`: **AI summary of failed job logs** (Massive token saver!).
- `github-mcp-server-summarize_run_log_failures`: **AI summary of full workflow run failures**.

### Pull Requests
- `github-mcp-server-create_pull_request`: Create PR with title, body, head, and base.
- `github-mcp-server-pull_request_read`: Read PR details, diff, status, reviews, comments, and checks.
- `github-mcp-server-update_pull_request`: Update PR title, body, state, or base.
- `github-mcp-server-merge_pull_request`: Merge PR using merge, squash, or rebase.
- `github-mcp-server-request_copilot_review`: Request Copilot automated code review on GitHub.
- `github-mcp-server-pull_request_review_write`: Submit formal review comments or approvals.

### Issues & Discussions
- `github-mcp-server-list_issues` / `github-mcp-server-issue_read`: Query repository issues.
- `github-mcp-server-issue_write`: Create or update issues and assignees.
- `github-mcp-server-add_issue_comment`: Add comment to an issue or pull request.
- `github-mcp-server-semantic_issue_similarity_search`: Find duplicate or related issues.

### Security & Alerts
- `github-mcp-server-list_dependabot_alerts` / `github-mcp-server-get_dependabot_alert`: Dependabot findings.
- `github-mcp-server-list_code_scanning_alerts`: Static analysis and CodeQL alerts.
- `github-mcp-server-get_secret_scanning_alert`: Secret leak detections.
- `github-mcp-server-run_secret_scanning`: Scan arbitrary code or diffs for leaked secrets.
- `github-mcp-server-check_dependency_vulnerabilities`: Match dependencies with GitHub Advisory Database.

### Releases & Git Data
- `github-mcp-server-list_releases` / `github-mcp-server-get_latest_release`: Query releases and assets.
- `github-mcp-server-list_commits` / `github-mcp-server-get_commit`: Inspect commit history and patches.
- `github-mcp-server-search_code`: Search code across GitHub.
