#!/usr/bin/env bash
set -euo pipefail

# tools/clean.sh: Cleans makepkg build artifacts, temporary directories, and downloaded source archives from packages/.
# Usage: ./tools/clean.sh [--pkg <name>] [--dry-run] [--force]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_DIR"

TARGET_PKG=""
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pkg) TARGET_PKG="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force|-f) FORCE=true; shift ;;
    -h|--help)
      echo "Usage: $0 [--pkg <package-name>] [--dry-run] [--force]"
      echo ""
      echo "Options:"
      echo "  --pkg <name>   Clean only a specific package in packages/<name>"
      echo "  --dry-run      List files and directories that would be removed without deleting"
      echo "  --force, -f    Skip interactive confirmation prompt"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

SEARCH_DIRS=()
if [ -n "$TARGET_PKG" ]; then
  if [ -d "packages/$TARGET_PKG" ]; then
    SEARCH_DIRS=("packages/$TARGET_PKG")
  else
    echo "Error: Directory 'packages/$TARGET_PKG' not found." >&2
    exit 1
  fi
else
  SEARCH_DIRS=("packages"/*)
fi

echo "Scanning for build artifacts..."
declare -A SEEN=()
ITEMS_TO_DELETE=()

add_item() {
  local item="$1"
  if [ -e "$item" ] && [ -z "${SEEN[$item]:-}" ]; then
    SEEN["$item"]=1
    ITEMS_TO_DELETE+=("$item")
  fi
}

for p in "${SEARCH_DIRS[@]}"; do
  [ -d "$p" ] || continue
  
  # Check for src/ and pkg/ directories
  for d in "$p/src" "$p/pkg"; do
    [ -d "$d" ] && add_item "$d"
  done

  # Check for package archive outputs
  shopt -s nullglob
  for f in "$p"/*.pkg.tar.*; do
    add_item "$f"
  done

  # Check for downloaded archives and upstream installers
  for f in "$p"/*.deb "$p"/*.AppImage "$p"/*.xpi "$p"/*.zip "$p"/*.rpm; do
    add_item "$f"
  done

  # Check for downloaded tarballs that are not tracked in git
  for f in "$p"/*.tar.* "$p"/*.tar; do
    if [ -f "$f" ] && ! git ls-files --error-unmatch "$f" &>/dev/null; then
      add_item "$f"
    fi
  done
  shopt -u nullglob
done

if [ ${#ITEMS_TO_DELETE[@]} -eq 0 ]; then
  echo "Clean! No build artifacts or temporary files found."
  exit 0
fi

echo "Found ${#ITEMS_TO_DELETE[@]} item(s) to clean:"
for item in "${ITEMS_TO_DELETE[@]}"; do
  if [ -d "$item" ]; then
    echo "  [dir]  $item"
  else
    SIZE=$(du -h "$item" 2>/dev/null | cut -f1 || echo "0")
    echo "  [file] $item (${SIZE})"
  fi
done

if [ "$DRY_RUN" = "true" ]; then
  echo ""
  echo "Dry run complete. No files were deleted."
  exit 0
fi

if [ "$FORCE" != "true" ]; then
  echo ""
  read -r -p "Do you want to permanently delete these items? [y/N] " response
  if [[ ! "$response" =~ ^[yY]([eE][sS])?$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

for item in "${ITEMS_TO_DELETE[@]}"; do
  rm -rf "$item"
done

echo "Successfully cleaned ${#ITEMS_TO_DELETE[@]} item(s)."
