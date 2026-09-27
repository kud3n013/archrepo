# Example: Offloading CI Failure Analysis to Copilot CLI

## Scenario
A scheduled GitHub Actions run of `build.yml` failed in `kud3n013/archrepo`. The run contains logs for package discovery, upstream checking, and Docker-based container builds spanning 10,000+ lines.

## Traditional Inefficient Approach
1. Antigravity runs `gh run view --log-failed`.
2. Antigravity dumps 50,000 tokens of raw log text into its context window.
3. Rapid context exhaustion, slowing down inference and consuming tokens.

## Copilot Offloading Approach
1. Antigravity executes Copilot CLI with GitHub MCP tools enabled:
   ```bash
   ./.agents/skills/copilot-cli-assistant/scripts/ci_diagnose.sh kud3n013/archrepo build.yml
   ```
2. Copilot uses `github-mcp-server-summarize_job_log_failures` on the remote server.
3. Copilot returns a ~300-word synthesized diagnosis:
   - Run ID: `12345678`
   - Failing Package: `packages/beeper`
   - Error: `curl: (22) The requested URL returned error: 404 Not Found` for upstream archive.
   - Recommended Fix: Update `upstream.json` check URL or regex pattern.
4. **Token Savings**: >98% token reduction in Antigravity's context window.
