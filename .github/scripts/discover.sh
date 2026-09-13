#!/usr/bin/env bash
set -euo pipefail

# discover.sh: Determines which packages need to be built and generates matrix output for GitHub Actions.
# Usage: discover.sh [--event <event>] [--before <sha>] [--head <sha>] [--package <name>] [--force <bool>] [--check-upstream <bool>] [--output <file>]

EVENT="${EVENT:-push}"
BEFORE_SHA="${BEFORE_SHA:-}"
HEAD_SHA="${HEAD_SHA:-HEAD}"
INPUT_PKG="${INPUT_PKG:-all}"
FORCE_REBUILD="${FORCE_REBUILD:-false}"
CHECK_UPSTREAM="${CHECK_UPSTREAM:-false}"
OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/stdout}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event) EVENT="$2"; shift 2 ;;
    --before) BEFORE_SHA="$2"; shift 2 ;;
    --head) HEAD_SHA="$2"; shift 2 ;;
    --package) INPUT_PKG="$2"; shift 2 ;;
    --force) FORCE_REBUILD="$2"; shift 2 ;;
    --check-upstream) CHECK_UPSTREAM="$2"; shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_DIR"

# Collect all valid package directories (excluding archive/)
ALL_PACKAGES=()
for d in */; do
  pkg="${d%/}"
  if [ -f "$pkg/PKGBUILD" ] && [ "$pkg" != "archive" ]; then
    ALL_PACKAGES+=("$pkg")
  fi
done

declare -A PACKAGES_TO_BUILD=()  # pkg -> update_needed (true/false)

# Helper: fetch release assets once if needed
RELEASE_ASSETS=""
get_release_assets() {
  if [ -z "$RELEASE_ASSETS" ]; then
    RELEASE_ASSETS=$(gh release view packages --repo "${GITHUB_REPOSITORY:-kud3n013/archrepo}" --json assets --jq '.assets[].name' 2>/dev/null || true)
  fi
}

is_binary_missing() {
  local pkg="$1"
  get_release_assets
  local ver rel
  ver=$(grep -oP '^pkgver=\K.*' "${pkg}/PKGBUILD" | tr -d '"'\' | head -1)
  rel=$(grep -oP '^pkgrel=\K.*' "${pkg}/PKGBUILD" | tr -d '"'\' | head -1)
  # Check if any asset starts with pkg-ver-rel
  if echo "$RELEASE_ASSETS" | grep -qE "^${pkg}-${ver}-${rel}-"; then
    return 1 # not missing
  fi
  return 0 # missing
}

echo "=== Package Discovery ==="
echo "Event: ${EVENT}"
echo "Input Package: ${INPUT_PKG}"
echo "Force Rebuild: ${FORCE_REBUILD}"
echo "Check Upstream: ${CHECK_UPSTREAM}"

if [ "$EVENT" = "workflow_dispatch" ]; then
  if [ "$INPUT_PKG" != "all" ] && [ -n "$INPUT_PKG" ]; then
    if [ -d "$INPUT_PKG" ] && [ -f "$INPUT_PKG/PKGBUILD" ]; then
      PACKAGES_TO_BUILD["$INPUT_PKG"]="false"
      if [ "$CHECK_UPSTREAM" = "true" ]; then
        RES=$("${SCRIPT_DIR}/check-upstream.sh" "$INPUT_PKG" || true)
        if echo "$RES" | grep -q '^UPDATE_NEEDED=true'; then
          PACKAGES_TO_BUILD["$INPUT_PKG"]="true"
        fi
      fi
    else
      echo "Error: Requested package '${INPUT_PKG}' not found." >&2
      exit 1
    fi
  else
    # workflow_dispatch for all packages
    for pkg in "${ALL_PACKAGES[@]}"; do
      if [ "$FORCE_REBUILD" = "true" ]; then
        PACKAGES_TO_BUILD["$pkg"]="false"
      elif [ "$CHECK_UPSTREAM" = "true" ]; then
        RES=$("${SCRIPT_DIR}/check-upstream.sh" "$pkg" || true)
        if echo "$RES" | grep -q '^UPDATE_NEEDED=true'; then
          PACKAGES_TO_BUILD["$pkg"]="true"
        elif is_binary_missing "$pkg"; then
          PACKAGES_TO_BUILD["$pkg"]="false"
        fi
      elif is_binary_missing "$pkg"; then
        PACKAGES_TO_BUILD["$pkg"]="false"
      fi
    done
  fi

elif [ "$EVENT" = "schedule" ]; then
  # Scheduled daily run: check all packages for upstream updates
  for pkg in "${ALL_PACKAGES[@]}"; do
    RES=$("${SCRIPT_DIR}/check-upstream.sh" "$pkg" || true)
    if echo "$RES" | grep -q '^UPDATE_NEEDED=true'; then
      echo "Update found for ${pkg}"
      PACKAGES_TO_BUILD["$pkg"]="true"
    elif is_binary_missing "$pkg"; then
      echo "Binary missing in release for ${pkg}"
      PACKAGES_TO_BUILD["$pkg"]="false"
    fi
  done

else
  # Push event: detect changed packages from git diff
  CHANGED_FILES=""
  DIFF_OK=false
  if [ -n "$BEFORE_SHA" ] && [ "$BEFORE_SHA" != "0000000000000000000000000000000000000000" ]; then
    if CHANGED_FILES=$(git diff --name-only "$BEFORE_SHA" "$HEAD_SHA" 2>/dev/null); then
      DIFF_OK=true
    fi
  fi
  if [ "$DIFF_OK" = "false" ]; then
    CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || true)
  fi

  echo "Changed files in commit range:"
  echo "$CHANGED_FILES" | sed 's/^/  /'

  WORKFLOW_OR_CI_CHANGED=false
  if echo "$CHANGED_FILES" | grep -qE '^(\.github/|PKGBUILD)'; then
    WORKFLOW_OR_CI_CHANGED=true
  fi

  for pkg in "${ALL_PACKAGES[@]}"; do
    if echo "$CHANGED_FILES" | grep -q "^${pkg}/"; then
      PKG_FILES=$(echo "$CHANGED_FILES" | grep "^${pkg}/" || true)
      NON_METADATA_FILES=$(echo "$PKG_FILES" | grep -vE "^${pkg}/(upstream\.json|\.SRCINFO)$" || true)
      if [ -n "$NON_METADATA_FILES" ] || is_binary_missing "$pkg"; then
        echo "Package modified: ${pkg}"
        PACKAGES_TO_BUILD["$pkg"]="false"
      else
        echo "Only metadata changed and binary already published: ${pkg}"
      fi
    elif [ "$WORKFLOW_OR_CI_CHANGED" = "true" ] && is_binary_missing "$pkg"; then
      echo "CI modified and package binary missing: ${pkg}"
      PACKAGES_TO_BUILD["$pkg"]="false"
    fi
  done
fi

# Build JSON matrix
MATRIX_ITEMS=()
for pkg in "${!PACKAGES_TO_BUILD[@]}"; do
  UPSTREAM_CHECK="none"
  UPSTREAM_REPO=""
  if [ -f "${pkg}/upstream.json" ]; then
    UPSTREAM_CHECK=$(jq -r '.check // "none"' "${pkg}/upstream.json")
    UPSTREAM_REPO=$(jq -r '.repo // ""' "${pkg}/upstream.json")
  fi
  UPDATE_NEEDED="${PACKAGES_TO_BUILD[$pkg]}"
  
  MATRIX_ITEMS+=("{\"name\":\"${pkg}\",\"upstream_check\":\"${UPSTREAM_CHECK}\",\"upstream_repo\":\"${UPSTREAM_REPO}\",\"update_needed\":${UPDATE_NEEDED}}")
done

COUNT=${#MATRIX_ITEMS[@]}
if [ "$COUNT" -gt 0 ]; then
  HAS_PACKAGES="true"
  # Join matrix items with commas
  MATRIX_JSON=$(IFS=,; echo "[${MATRIX_ITEMS[*]}]")
else
  HAS_PACKAGES="false"
  MATRIX_JSON="[]"
fi

FULL_MATRIX="{\"include\":${MATRIX_JSON}}"

echo "Packages to build count: ${COUNT}"
echo "Has packages: ${HAS_PACKAGES}"
echo "Matrix JSON: ${FULL_MATRIX}"

# Write to GitHub Output
{
  echo "matrix=${FULL_MATRIX}"
  echo "has_packages=${HAS_PACKAGES}"
  echo "count=${COUNT}"
} >> "$OUTPUT_FILE"
