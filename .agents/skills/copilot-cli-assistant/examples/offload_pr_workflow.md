# Example: Offloading PR Creation & Code Review

## Scenario
You have created or updated a package in `packages/zed/` (modified `PKGBUILD`, updated `.SRCINFO`). Before submitting the change or opening a PR, you want to review the diff and generate a clean pull request.

## Step 1: Pre-commit Agentic Code Review
Run Copilot CLI to audit the diff:
```bash
./.agents/skills/copilot-cli-assistant/scripts/code_review.sh
```
Copilot inspects `git diff` using its read-only git tool and returns findings on PKGBUILD linting, variable quoting, and `.SRCINFO` alignment.

## Step 2: Offload PR Creation via GitHub MCP
Once committed, run Copilot to generate the PR and description:
```bash
copilot -p "Open a pull request to origin/main using github-mcp-server-create_pull_request. Summarize the changes made in packages/zed, including the upstream version bump and SHA256 checksum updates." \
  --add-github-mcp-tool "create_pull_request" \
  --allow-tool='github-mcp-server(create_pull_request)' \
  --allow-tool='shell(git diff:*)' \
  --allow-tool='shell(git log:*)' \
  --allow-tool='shell(git status:*)' \
  --no-ask-user \
  -s --no-color
```

## Step 3: Remote Delegation (Alternative)
If you want the entire package creation or bug fix implemented on GitHub's cloud without touching local compute or tokens, enter interactive mode or use:
```text
/delegate Implement a new package in packages/superlist using the template in templates/NEW_PACKAGE_PROMPT_TEMPLATE.md and open a pull request against main
```
Copilot Cloud Agent executes on GitHub's infrastructure and produces the PR directly.
