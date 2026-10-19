#!/usr/bin/env bash
set -euo pipefail

# kwin-watch.sh: Dispatches a rebuild for packages with "rebuild_on": "kwin"
# when Arch's kwin package differs from the _kwinver recorded in their PKGBUILD.
#
# Reads kwin's version from a mirror's extra.db, not archlinux.org, so it needs
# no Arch container. A failure to check is an error, never "no change".
#
# Env:
#   DRY_RUN=1          report what would be dispatched, dispatch nothing
#   STATE_FILE         JSON cache of the last seen database (default: .kwin-watch-state.json)
#   KWIN_WATCH_MIRRORS space-separated mirror base URLs, tried in order
#   GH_REPO            owner/repo for gh (default: kud3n013/archrepo)
#   KWIN_RETRY_HOURS   hours before a failed bump PR is retried (default: 6)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/../.."

DRY_RUN="${DRY_RUN:-0}"
STATE_FILE="${STATE_FILE:-.kwin-watch-state.json}"
GH_REPO="${GH_REPO:-kud3n013/archrepo}"
RETRY_HOURS="${KWIN_RETRY_HOURS:-6}"
USER_AGENT="archrepo-kwin-watch (+https://github.com/kud3n013/archrepo)"
# geo.mirror.pkgbuild.com is what the archlinux Docker image uses, so the build
# containers see the same state; the others are widely used fallbacks.
MIRRORS="${KWIN_WATCH_MIRRORS:-https://geo.mirror.pkgbuild.com https://mirror.leaseweb.net/archlinux https://mirrors.kernel.org/archlinux}"

SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Packages that must follow kwin
PACKAGES=()
for cfg in packages/*/upstream.json; do
  [ -f "$cfg" ] || continue
  if [ "$(jq -r '.rebuild_on // ""' "$cfg")" = "kwin" ]; then
    PACKAGES+=("$(basename "$(dirname "$cfg")")")
  fi
done
if [ ${#PACKAGES[@]} -eq 0 ]; then
  echo "No package uses rebuild_on=kwin."
  exit 0
fi

# Cached state from the previous poll: lets most polls end in a cheap 304
S_MIRROR=""; S_MODIFIED=""; S_VERSION=""
if [ -s "$STATE_FILE" ]; then
  S_MIRROR=$(jq -r '.mirror // ""' "$STATE_FILE" 2>/dev/null || true)
  S_MODIFIED=$(jq -r '.last_modified // ""' "$STATE_FILE" 2>/dev/null || true)
  S_VERSION=$(jq -r '.version // ""' "$STATE_FILE" 2>/dev/null || true)
fi

KWIN=""
USED=""
STATUS=""
for mirror in $MIRRORS; do
  url="${mirror%/}/extra/os/x86_64/extra.db"
  cond=()
  if [ "$mirror" = "$S_MIRROR" ] && [ -n "$S_MODIFIED" ] && [ -n "$S_VERSION" ]; then
    cond=(-H "If-Modified-Since: ${S_MODIFIED}")
  fi
  code=$(curl -sSL --max-time 90 --retry 1 --retry-delay 3 -A "$USER_AGENT" "${cond[@]}" \
    -D "$WORK/headers" -o "$WORK/extra.db" -w '%{http_code}' "$url" 2>"$WORK/curl.err" || true)

  if [ "$code" = "304" ]; then
    KWIN="$S_VERSION"; USED="$mirror"; STATUS="not modified since ${S_MODIFIED}"
    break
  elif [ "$code" = "200" ]; then
    # Entries are <name>-<ver>-<rel>/desc; the digit excludes kwin-x11 and friends
    # (GNU tar and bsdtar both detect gzip/zstd on their own)
    desc=$(tar -xOf "$WORK/extra.db" --wildcards 'kwin-[0-9]*/desc' 2>/dev/null || bsdtar -xOf "$WORK/extra.db" 'kwin-[0-9]*/desc' 2>/dev/null || true)
    name=$(awk '/^%NAME%$/{getline; print; exit}' <<< "$desc")
    ver=$(awk '/^%VERSION%$/{getline; print; exit}' <<< "$desc")
    if [ "$name" = "kwin" ] && [[ "$ver" =~ ^[0-9A-Za-z._+:-]+$ ]]; then
      KWIN="$ver"; USED="$mirror"
      modified=$(grep -i '^last-modified:' "$WORK/headers" | tail -1 | cut -d' ' -f2- | tr -d '\r' || true)
      STATUS="downloaded (${modified:-no Last-Modified})"
      jq -n --arg m "$mirror" --arg l "$modified" --arg v "$KWIN" \
        '{mirror: $m, last_modified: $l, version: $v}' > "$STATE_FILE"
      echo "state_changed=true" >> "${GITHUB_OUTPUT:-/dev/null}"
      break
    fi
    echo "::warning::${url}: could not find kwin in the database, trying the next mirror"
  else
    echo "::warning::${url}: HTTP ${code:-000} $(head -c 200 "$WORK/curl.err"), trying the next mirror"
  fi
done

if [ -z "$KWIN" ]; then
  echo "::error::Could not read Arch's kwin version from any mirror ($MIRRORS); the kwin rebuild check did not run"
  printf '### kwin watch: FAILED\nNo mirror answered.\n' >> "$SUMMARY"
  exit 1
fi
echo "Arch kwin: ${KWIN} (${USED}, ${STATUS})"
{
  echo "### kwin watch"
  echo "- Arch kwin: \`${KWIN}\`"
  echo "- Mirror: ${USED} (${STATUS})"
} >> "$SUMMARY"

# True if a build.yml run is queued or running. It cannot be tied to a package
# (inputs are not exposed), but a run that is still going will either pick the
# change up or finish before the next poll retries.
run_in_flight() {
  local status n
  for status in queued in_progress waiting pending requested; do
    if ! n=$(gh run list --repo "$GH_REPO" --workflow build.yml --status "$status" --json databaseId --jq length 2>"$WORK/gh.err"); then
      echo "::warning::Could not list ${status} build.yml runs ($(head -c 200 "$WORK/gh.err")); assuming none"
      n=0
    fi
    [ "${n:-0}" -gt 0 ] && return 0
  done
  return 1
}

DISPATCH_FAILED=0
for pkg in "${PACKAGES[@]}"; do
  recorded=$(grep -oP '^_kwinver=\K.*' "packages/${pkg}/PKGBUILD" | tr -d '"'\' | head -1 || true)
  if [ -z "$recorded" ]; then
    echo "::error::packages/${pkg}/PKGBUILD has no _kwinver= line"
    echo "- \`${pkg}\`: no \`_kwinver\` recorded" >> "$SUMMARY"
    DISPATCH_FAILED=1
    continue
  fi
  if [ "$recorded" = "$KWIN" ]; then
    echo "${pkg}: up to date (${recorded})"
    echo "- \`${pkg}\`: up to date (\`${recorded}\`)" >> "$SUMMARY"
    continue
  fi
  echo "${pkg}: _kwinver ${recorded} != Arch kwin ${KWIN}"

  if run_in_flight; then
    echo "${pkg}: already pending (a build.yml run is queued or in progress)"
    echo "- \`${pkg}\`: \`${recorded}\` -> \`${KWIN}\`, already pending (build run in flight)" >> "$SUMMARY"
    continue
  fi

  # An open bump PR for this very kwin means a build was already tried and did not
  # merge (failed, or needs a review). Retry only after RETRY_HOURS without activity
  # so a persistent failure does not rebuild every poll.
  if ! pr=$(gh pr list --repo "$GH_REPO" --head "bump/${pkg}" --state open --json number,updatedAt --jq '.[0] // empty' 2>"$WORK/gh.err"); then
    echo "::warning::Could not list bump PRs ($(head -c 200 "$WORK/gh.err")); the failed-build backoff does not apply"
    pr=""
  fi
  if [ -n "$pr" ]; then
    pr_num=$(jq -r '.number' <<< "$pr")
    pr_updated=$(jq -r '.updatedAt' <<< "$pr")
    pr_kwin=$(gh api "repos/${GH_REPO}/contents/packages/${pkg}/PKGBUILD?ref=bump/${pkg}" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null | grep -oP '^_kwinver=\K.*' | tr -d '"'\' | head -1 || true)
    age_h=$(( ( $(date +%s) - $(date -d "$pr_updated" +%s) ) / 3600 ))
    if [ "$pr_kwin" = "$KWIN" ] && [ "$age_h" -lt "$RETRY_HOURS" ]; then
      echo "${pkg}: already pending (bump PR #${pr_num} targets ${KWIN}, last activity ${age_h}h ago)"
      echo "- \`${pkg}\`: \`${recorded}\` -> \`${KWIN}\`, already pending (bump PR #${pr_num})" >> "$SUMMARY"
      continue
    fi
  fi

  if [ "$DRY_RUN" = "1" ]; then
    echo "DRY_RUN: would run: gh workflow run build.yml -f package=${pkg} -f check_upstream=true"
    echo "- \`${pkg}\`: \`${recorded}\` -> \`${KWIN}\`, **would dispatch** (dry run)" >> "$SUMMARY"
  elif gh workflow run build.yml --repo "$GH_REPO" -f "package=${pkg}" -f check_upstream=true; then
    echo "${pkg}: dispatched build.yml"
    echo "- \`${pkg}\`: \`${recorded}\` -> \`${KWIN}\`, **dispatched build.yml**" >> "$SUMMARY"
  else
    echo "::error::Failed to dispatch build.yml for ${pkg}"
    echo "- \`${pkg}\`: dispatch FAILED" >> "$SUMMARY"
    DISPATCH_FAILED=1
  fi
done

exit "$DISPATCH_FAILED"
