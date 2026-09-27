# Copilot CLI Prompt & Command Recipes

These recipes are optimized to offload work and context tokens to Copilot CLI. When Antigravity executes these via `run_command`, Copilot burns tokens on its own session and returns only the high-value synthesized output.

---

## 1. CI Workflow Failure Diagnostics (Massive Token Saver)

Instead of ingesting 5,000+ lines of GitHub Actions runner output into Antigravity's context window:

### Command
```bash
copilot -p "Use github-mcp-server-summarize_run_log_failures to inspect the latest failed workflow run for kud3n013/archrepo. Identify: 1) Failed package or step, 2) Exact root-cause error message, 3) Suggested fix in PKGBUILD or workflow." \
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

### Prompt Pattern
```text
Inspect the latest failed run of the 'build.yml' workflow in kud3n013/archrepo using the GitHub Actions MCP tools.
Do not dump raw logs. Provide:
- Which package(s) failed in discover/build
- The exact compiler / makepkg / pacman error
- Actionable code edits to fix the failure
```

---

## 2. Agentic Code Review (Pre-Commit / Pre-Push Audit)

Offloads large diff inspection and deep reasoning about edge cases, bash syntax, and packaging conventions.

### Command
```bash
copilot -p "Run an agentic code review of all uncommitted changes (staged and unstaged) in this git repository. Focus on:
1. Shell script safety (SC rules, quote handling, error trapping in .sh and PKGBUILD)
2. Arch Linux packaging standards (.SRCINFO synchronization, correct pkgrel reset, dependency accuracy)
3. Potential regressions or breaking changes
Return findings ordered by severity (Critical, Warning, Suggestion) with exact file:line references and diff fixes." \
  --allow-tool='shell(git diff)' \
  --allow-tool='shell(git diff HEAD)' \
  --allow-tool='shell(git status)' \
  --deny-tool='shell(*--output*)' \
  --deny-tool='shell(*-o *)' \
  --no-ask-user \
  -s --no-color
```

---

## 3. Pull Request Creation with Auto-Generated Body

Offloads diff exploration, commit message drafting, and PR description formatting.

### Command
```bash
copilot -p "Analyze git changes against origin/main. Create a pull request to origin/main using github-mcp-server-create_pull_request with:
- Conventional commit title (e.g., feat(pkg): add package-xyz, fix(ci): resolve makepkg retry)
- Summary of changes
- Packages affected
- Verification steps undertaken" \
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

---

## 4. Security Audit & Vulnerability Check

Offloads secret detection, advisory lookups, and dependency scanning.

### Command
```bash
copilot -p "Run security analysis on recently modified files and diffs. Check for:
1. Leaked tokens, private keys, or credentials
2. Untrusted download URLs without checksum verification (sha256sums='SKIP')
3. Insecure shell patterns (eval, curl|bash without hash check)
Use run_secret_scanning and report any findings." \
  --add-github-mcp-tool "run_secret_scanning" \
  --add-github-mcp-tool "check_dependency_vulnerabilities" \
  --allow-tool='github-mcp-server(run_secret_scanning)' \
  --allow-tool='github-mcp-server(check_dependency_vulnerabilities)' \
  --allow-tool='shell(git diff)' \
  --allow-tool='shell(git log -n 5)' \
  --allow-tool='shell(git status)' \
  --deny-tool='shell(*--output*)' \
  --deny-tool='shell(*-o *)' \
  --no-ask-user \
  -s --no-color
```

---

## 5. Autopilot Autonomous Fix (Multi-step Task Offload)

Runs an autonomous bounded sub-agent locally to perform multi-file edits, metadata generation, and verification.

### Command
```bash
copilot --autopilot --yolo --max-autopilot-continues 5 -p "Update packages/my-pkg/PKGBUILD to upstream version 1.2.3. Regenerate .SRCINFO using makepkg --printsrcinfo. Run git diff to verify correctness."
```
