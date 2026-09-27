---
name: copilot-cli-assistant
description: >-
  Offload token-intensive and repository-centric operations to GitHub Copilot CLI.
  Use this skill when you need to perform agentic code reviews, diagnose GitHub Actions
  workflow failures and large build logs, manage pull requests, audit security vulnerabilities,
  or delegate autonomous multi-step tasks to Copilot CLI or GitHub Cloud Agent to conserve context tokens.
allowed-tools: shell
---

# Copilot CLI Assistant Skill

This skill teaches the agent how to leverage the local GitHub Copilot CLI (v1.0.88+) and its integrated GitHub MCP server to offload heavy computation, massive log processing, diff reviews, and repository management tasks.

By delegating these tasks to Copilot CLI, the primary assistant saves significant context tokens, avoids context window compaction, and benefits from Copilot's built-in GitHub API and MCP tool integrations.

---

## 1. Quick Decision Matrix: When to Offload

| Task | Offload Method | Benefit | Token Savings |
| :--- | :--- | :--- | :--- |
| **CI Workflow Failure Diagnosis** | `ci_diagnose.sh` or MCP `summarize_run_log_failures` | Extracts root cause directly from GitHub Actions without streaming megabytes of build logs into context | **95–99%** |
| **Pre-Commit Code Review** | `code_review.sh` or `copilot -p ...` with git tool | Reviews uncommitted diffs for ShellCheck, PKGBUILD linting, and regressions | **80–90%** |
| **Pull Request Lifecycle** | Copilot with `--add-github-mcp-tool "*"` or `/pr` | Drafts PR titles, structured bodies, checklists, and addresses reviewer comments | **70–85%** |
| **Security & Secrets Audit** | Copilot MCP `run_secret_scanning` | Scans diffs and repo for credentials, unverified hashes, and unsafe shell calls | **90%** |
| **Multi-File Autonomous Coding** | `copilot --autopilot --yolo --max-autopilot-continues 5` | Executes edits, builds, and verification autonomously in a separate session | **100% of intermediate turns** |
| **Cloud Task Delegation** | Copilot `/delegate <task> --base main` | Hands off implementation entirely to GitHub Cloud Agent; work happens in background | **100% of local compute & tokens** |

---

## 2. Command Architecture & Permission Rules

Copilot CLI commands executed by the agent should adhere to these execution guidelines:

### Non-Interactive Invocations
Always include these flags when running programmatically via `run_command`:
- `-p "<prompt>"`: Passes the objective directly.
- `-s` or `--silent`: Outputs only the final response text (omits header banners and stats).
- `--no-color`: Strips ANSI color codes for clean machine-readable markdown output.
- `--no-ask-user`: Disables the interactive user question prompt so the command never blocks on user input.

### Permission Configurations

Copilot CLI restricts tool execution by default. Configure explicit permissions:

1. **Read-only Git Operations**:
   `--allow-tool='shell(git status)' --allow-tool='shell(git diff)' --allow-tool='shell(git log -n 5)' --deny-tool='shell(*--output*)' --deny-tool='shell(*-o *)'`
   *(Note: Prefer passing a precomputed diff snapshot directly in the prompt as demonstrated in `code_review.sh`—this requires zero shell tool permissions).*
2. **Read-only GitHub CLI Operations**:
   `--allow-tool='shell(gh pr view:*)' --allow-tool='shell(gh run list:*)' --allow-tool='shell(gh run view:*)'`
3. **File Modifications**:
   `--allow-tool='write'` or granular `--allow-tool='write(packages/*)'`
4. **GitHub MCP Server Tools**:
   - Read-only default: `--add-github-mcp-tool "actions_list" --add-github-mcp-tool "actions_get" --add-github-mcp-tool "summarize_job_log_failures" --add-github-mcp-tool "summarize_run_log_failures" --allow-tool=github-mcp-server`
   - Full access (with write capabilities): `--add-github-mcp-tool "*"` with `--allow-tool=github-mcp-server`
5. **Full Autonomous Permission**:
   `--allow-all` or `--yolo` (combines all tools, paths, and URLs; essential for `--autopilot`)

For detailed permission patterns and native/MCP tool lists, see [Tools & Permissions Reference](./references/tools_and_permissions.md).

---

## 3. High-Impact Workflows for `archrepo`

### Workflow A: Diagnose GitHub Actions CI Failure

When a build fails in `archrepo` (e.g. `build.yml`), do **not** run `gh run view --log-failed` directly into context. Instead, run:

```bash
./.agents/skills/copilot-cli-assistant/scripts/ci_diagnose.sh "kud3n013/archrepo" "build.yml"
```

Or execute the inline command:
```bash
copilot -p "Use the GitHub Actions MCP tools to find the latest failed run of 'build.yml' in 'kud3n013/archrepo'. Summarize: 1) Failed package, 2) Root cause error from logs, 3) Exact file edit needed." \
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
```

*Example Output*:
> Package `packages/zed` failed during `makepkg` step: upstream release v0.145.0 changed archive structure. Edit `PKGBUILD` source extraction path from `zed-v0.145.0` to `zed-linux-x86_64`.

### Workflow B: Agentic Code Review on Diffs

Before committing or pushing PKGBUILD and bash script changes:

```bash
./.agents/skills/copilot-cli-assistant/scripts/code_review.sh
```

Or execute the inline command with exact read-only queries and output denials:
```bash
copilot -p "Review unstaged and staged git changes. Focus on Arch packaging rules (variables, .SRCINFO alignment, pkgrel reset), ShellCheck best practices in scripts/, and CI workflow integrity. Return findings in markdown with exact diff suggestions." \
  --allow-tool='shell(git diff)' \
  --allow-tool='shell(git diff HEAD)' \
  --allow-tool='shell(git status)' \
  --deny-tool='shell(*--output*)' \
  --deny-tool='shell(*-o *)' \
  --no-ask-user \
  -s --no-color
```

### Workflow C: Pull Request Creation & Management

To create a PR with full metadata, changelog summary, and test verification:

```bash
copilot -p "Analyze git changes against origin/main. Using github-mcp-server-create_pull_request, create a PR to origin/main with conventional commit title, summary of packages modified, and verification steps." \
  --add-github-mcp-tool "create_pull_request" \
  --allow-tool='github-mcp-server(create_pull_request)' \
  --allow-tool='shell(git diff)' \
  --allow-tool='shell(git log -n 5)' \
  --allow-tool='shell(git status)' \
  --deny-tool='shell(*--output*)' \
  --deny-tool='shell(*-o *)' \
  --no-ask-user \
  -s --no-color
```

### Workflow D: Autonomous Package Scaffolding & Upstream Updates

To run an autonomous task bounded to 5 continuations (e.g., scaffolding a package or updating `.SRCINFO`):

```bash
copilot --autopilot --yolo --max-autopilot-continues 5 \
  -p "Scaffold a new package named 'sample-app' using ./tools/scaffold.sh sample-app upstream/repo, generate .SRCINFO, and verify git status."
```

### Workflow E: Remote Task Delegation to Copilot Cloud Agent

To offload a feature or package implementation to GitHub without running local processes:
- In an interactive session or prompt:
  ```text
  /delegate Add package recipe for 'ripgrep-all' in packages/ripgrep-all following conventions in .github/copilot-instructions.md --base main
  ```
- Or prefix prompt with `&`:
  ```text
  &Add package recipe for 'ripgrep-all' in packages/ripgrep-all
  ```
Copilot Cloud Agent opens a branch and a draft pull request directly on GitHub.

---

## 4. Helper Scripts Reference

The skill includes executable helper scripts in `scripts/`:

| Script | Purpose | Usage |
| :--- | :--- | :--- |
| [`copilot_exec.sh`](./scripts/copilot_exec.sh) | Generic robust runner with flag parsing and usage logging | `./copilot_exec.sh --with-mcp --allow-git -- "Your prompt"` |
| [`ci_diagnose.sh`](./scripts/ci_diagnose.sh) | Analyzes failed CI runs using GitHub Actions MCP log summarizer | `./ci_diagnose.sh [repo] [workflow]` |
| [`code_review.sh`](./scripts/code_review.sh) | Performs rigorous code review of current git diff | `./code_review.sh [base-ref]` |

---

## 5. Verification & Best Practices

1. **Verify Exit Status**: Ensure commands exit with code `0`. If Copilot CLI times out or errors, inspect task logs in `.system_generated/tasks/`.
2. **Monitor AI Credits**: To track token and credit expenditure, pass `--usage-output-file /tmp/copilot-usage.json` to `copilot`.
3. **Repository Instructions**: Keep [`.github/copilot-instructions.md`](../../../.github/copilot-instructions.md) updated so Copilot CLI always understands repo architecture and build conventions.
4. **Deduplicate Findings**: Synthesize Copilot's findings into your final response to the user; do not regurgitate raw command text.
