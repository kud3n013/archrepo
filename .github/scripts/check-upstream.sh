#!/usr/bin/env bash
set -euo pipefail

# check-upstream.sh: Checks upstream releases for a package and optionally applies updates.
# Usage: check-upstream.sh <pkg_dir> [--apply]

PKG_DIR="${1:-}"
APPLY="${2:-}"

if [ -z "$PKG_DIR" ] || [ ! -f "${PKG_DIR}/PKGBUILD" ]; then
  echo "Error: Directory '${PKG_DIR}' does not contain a PKGBUILD" >&2
  exit 1
fi

PKG=$(basename "$PKG_DIR")
CONFIG_FILE="${PKG_DIR}/upstream.json"

CHECK="none"
UPSTREAM=""

if [ -f "$CONFIG_FILE" ]; then
  CHECK=$(jq -r '.check // "none"' "$CONFIG_FILE")
  UPSTREAM=$(jq -r '.repo // ""' "$CONFIG_FILE")
fi

# Fallback: if no upstream.json, check if PKGBUILD URL is a GitHub repo.
# An explicit "check": "none" must stay disabled (e.g. packages whose url is this repo).
if [ ! -f "$CONFIG_FILE" ]; then
  URL=$(grep -oP '^url=["\x27]?\K[^"\x27]+' "${PKG_DIR}/PKGBUILD" || true)
  if [[ "$URL" =~ github\.com/([^/]+/[^/]+) ]]; then
    CHECK="github-release"
    UPSTREAM="${BASH_REMATCH[1]}"
  fi
fi

CURRENT=$(grep -oP '^pkgver=\K.*' "${PKG_DIR}/PKGBUILD" | tr -d '"'\' | head -1)
LATEST="$CURRENT"
UPDATE_NEEDED=false
EXTRA_INFO=""
NEW_BUILD=""
NEW_COMMIT=""

# GitHub Auth Header if GH_TOKEN or GITHUB_TOKEN is available
AUTH_HEADER=()
if [ -n "${GH_TOKEN:-}" ]; then
  AUTH_HEADER=(-H "Authorization: token ${GH_TOKEN}")
elif [ -n "${GITHUB_TOKEN:-}" ]; then
  AUTH_HEADER=(-H "Authorization: token ${GITHUB_TOKEN}")
fi

case "$CHECK" in
  github-release)
    if [ -n "$UPSTREAM" ]; then
      RELEASE_JSON=$(curl -s "${AUTH_HEADER[@]}" "https://api.github.com/repos/${UPSTREAM}/releases/latest" || true)
      TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty' 2>/dev/null || true)
      TAG="${TAG#v}"
      [ -n "$TAG" ] && [ "$TAG" != "null" ] && LATEST="$TAG"

      # Special handling for zalo-for-linux
      if [ "$PKG" = "zalo-for-linux" ]; then
        ASSET=$(echo "$RELEASE_JSON" | jq -r '.assets[].name' 2>/dev/null | grep -E '^Zalo-.*-([0-9a-fA-F]+)-x86_64\.AppImage$' | head -1 || true)
        if [ -n "$ASSET" ]; then
          NEW_COMMIT=$(echo "$ASSET" | grep -oP '\-\K[0-9a-fA-F]+(?=-x86_64\.AppImage)' || true)
          NEW_ZADARK=$(echo "$ASSET" | grep -oP '\+ZaDark-\K[0-9.]+(?=-)' || true)
          CURRENT_COMMIT=$(grep -oP '^_commithash=\K.*' "${PKG_DIR}/PKGBUILD" || true)
          if [ -n "$NEW_COMMIT" ] && [ "$NEW_COMMIT" != "$CURRENT_COMMIT" ]; then
            UPDATE_NEEDED=true
            EXTRA_INFO="commit: ${CURRENT_COMMIT} -> ${NEW_COMMIT}"
          fi
        fi
      fi
    fi
    ;;

  beeper-redirect)
    HEADERS=$(curl -sI -A "curl/8" "https://api.beeper.com/desktop/download/linux/x64/stable/com.automattic.beeper.desktop" || true)
    VER=$(echo "$HEADERS" | grep -i '^location:' | grep -oP 'Beeper-\K[0-9.]+(?=-x86_64\.AppImage)' | head -1 || true)
    [ -n "$VER" ] && LATEST="$VER"
    ;;

  zotero-redirect)
    HEADERS=$(curl -sI "https://www.zotero.org/download/client/dl?channel=release&platform=linux-x86_64" || true)
    VER=$(echo "$HEADERS" | grep -i '^location:' | grep -oP 'client/release/\K[0-9.]+(?=/Zotero)' | head -1 || true)
    [ -n "$VER" ] && LATEST="$VER"
    ;;

  cursor-redirect)
    HEADERS=$(curl -sI "https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/latest" || true)
    # Fall back to the current major.minor channel (e.g. 3.24.12 -> 3.24), never a hard-coded older one
    [ -z "$(echo "$HEADERS" | grep -i '^location:')" ] && HEADERS=$(curl -sI "https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/${CURRENT%.*}" || true)
    VER=$(echo "$HEADERS" | grep -i '^location:' | grep -oP 'cursor_\K[0-9.]+(?=_amd64\.deb)' | head -1 || true)
    NEW_COMMIT=$(echo "$HEADERS" | grep -i '^location:' | grep -oP 'production/\K[0-9a-fA-F]+(?=/linux)' | head -1 || true)
    [ -n "$VER" ] && LATEST="$VER"
    CURRENT_COMMIT=$(grep -oP '^_commithash=\K.*' "${PKG_DIR}/PKGBUILD" || true)
    if [ -n "$NEW_COMMIT" ] && [ "$NEW_COMMIT" != "$CURRENT_COMMIT" ]; then
      UPDATE_NEEDED=true
      EXTRA_INFO="commit: ${CURRENT_COMMIT} -> ${NEW_COMMIT}"
    fi
    ;;

  codeberg-release)
    if [ -n "$UPSTREAM" ]; then
      TAG=$(curl -s "https://codeberg.org/api/v1/repos/${UPSTREAM}/releases/latest" | jq -r '.tag_name // empty' 2>/dev/null || true)
      TAG="${TAG#v}"
      [ -n "$TAG" ] && [ "$TAG" != "null" ] && LATEST="$TAG"
    fi
    ;;

  antigravity-download)
    DOWNLOAD_HTML=$(curl -sL --compressed -A "Mozilla/5.0" "https://antigravity.google/download" || true)
    MATCH=$(echo "$DOWNLOAD_HTML" | grep -oP 'https://storage\.googleapis\.com/antigravity-public/antigravity-hub/\K[0-9.]+\-[0-9]+(?=/linux-x64/Antigravity\.tar\.gz)' | head -1 || true)
    if [ -n "$MATCH" ]; then
      VER="${MATCH%%-*}"
      NEW_BUILD="${MATCH##*-}"
      LATEST="$VER"
      CURRENT_BUILD=$(grep -oP '^_build=\K.*' "${PKG_DIR}/PKGBUILD" || true)
      if [ -n "$NEW_BUILD" ] && [ "$NEW_BUILD" != "$CURRENT_BUILD" ]; then
        UPDATE_NEEDED=true
        EXTRA_INFO="build: ${CURRENT_BUILD} -> ${NEW_BUILD}"
      fi
    fi
    ;;

  gdlauncher-cdn)
    VER=$(curl -s -A "Mozilla/5.0" "https://cdn-raw.gdl.gg/launcher/latest-linux.yml" | grep -oP '^version:\s*\K[0-9.]+' | head -1 || true)
    [ -n "$VER" ] && LATEST="$VER"
    ;;

  searxng-commit)
    if [ -n "$UPSTREAM" ]; then
      COMMITS_RESP=$(curl -sI "${AUTH_HEADER[@]}" -H "User-Agent: curl/8" "https://api.github.com/repos/${UPSTREAM}/commits?per_page=1" || true)
      COUNT=$(echo "$COMMITS_RESP" | grep -i '^link:' | grep -oP 'page=\K[0-9]+(?=>;\s*rel="last")' | head -1 || true)
      SHA_JSON=$(curl -s "${AUTH_HEADER[@]}" -H "User-Agent: curl/8" "https://api.github.com/repos/${UPSTREAM}/commits?per_page=1" || true)
      SHORT_SHA=$(echo "$SHA_JSON" | jq -r '.[0].sha[0:7] // empty' 2>/dev/null || true)
      if [ -n "$COUNT" ] && [ -n "$SHORT_SHA" ] && [ "$SHORT_SHA" != "null" ]; then
        LATEST="r${COUNT}.${SHORT_SHA}"
      fi
    fi
    ;;

  proton-mail-json)
    VER=$(curl -s "https://proton.me/download/mail/linux/version.json" | jq -r '.Releases[0].Version // empty' 2>/dev/null || true)
    [ -n "$VER" ] && [ "$VER" != "null" ] && LATEST="$VER"
    ;;

  proton-pass-json)
    VER=$(curl -s "https://proton.me/download/pass/linux/version.json" | jq -r '.Releases[0].Version // empty' 2>/dev/null || true)
    [ -n "$VER" ] && [ "$VER" != "null" ] && LATEST="$VER"
    ;;

  proton-pass-cli-json)
    VER=$(curl -s "https://proton.me/download/pass-cli/versions.json" | jq -r '.passCliVersions.version // empty' 2>/dev/null || true)
    [ -n "$VER" ] && [ "$VER" != "null" ] && LATEST="$VER"
    ;;

  proton-drive-cli-html)
    # Proton publishes no JSON feed for the Drive CLI; the download index page carries "Proton Drive CLI <ver>".
    VER=$(curl -s "https://proton.me/download/drive/cli/index.html" | grep -oP '<h1>Proton Drive CLI \K[0-9.]+' | head -1 || true)
    [ -n "$VER" ] && LATEST="$VER"
    ;;

  millennium-github-prerelease)
    # Millennium uses pre-release tags (e.g. v3.5.0-beta.3) which /releases/latest skips.
    # Fetch the most recent release with linux archive and drop hyphens (3.6.0-beta.1 -> 3.6.0beta.1)
    # so vercmp orders the prerelease before the final 3.6.0.
    if [ -n "$UPSTREAM" ]; then
      TAG=$(curl -s "${AUTH_HEADER[@]}" "https://api.github.com/repos/${UPSTREAM}/releases" | \
        jq -r '[.[] | select(.draft == false and (.assets[].name | test("linux-x86_64.*tar\\.gz")) )][0].tag_name // empty' 2>/dev/null || true)
      TAG="${TAG#v}"
      TAG="${TAG//-/}"
      [ -n "$TAG" ] && [ "$TAG" != "null" ] && LATEST="$TAG"
    fi
    ;;

  obsidian-desktop)
    # Obsidian releases include both mobile (e.g. Android apk only) and desktop builds.
    # Filter releases for the latest release containing the desktop debian package.
    if [ -n "$UPSTREAM" ]; then
      RELEASES_JSON=$(curl -s "${AUTH_HEADER[@]}" "https://api.github.com/repos/${UPSTREAM}/releases?per_page=20" || true)
      TAG=$(echo "$RELEASES_JSON" | jq -r '[.[] | select(.assets[].name | test("^obsidian_.*_amd64\\.deb$"))][0].tag_name // empty' 2>/dev/null || true)
      TAG="${TAG#v}"
      [ -n "$TAG" ] && [ "$TAG" != "null" ] && LATEST="$TAG"
    fi
    ;;

  none)
    ;;
esac

if [ "$LATEST" != "$CURRENT" ]; then
  if ! [[ "$LATEST" =~ ^[0-9A-Za-z._+]+$ ]]; then
    echo "Warning: Rejected upstream version with invalid characters: '${LATEST}'" >&2
    UPDATE_NEEDED=false
  elif ! command -v vercmp &>/dev/null; then
    echo "Error: vercmp (pacman) is required to compare versions" >&2
    exit 1
  elif [ "$(vercmp "$LATEST" "$CURRENT")" -lt 0 ]; then
    # A stale CDN redirect or a mis-sorted release list must never downgrade the
    # package; build/commit ids reported alongside belong to that older release.
    echo "Warning: Rejected upstream version older than current: '${LATEST}' < '${CURRENT}'" >&2
    UPDATE_NEEDED=false
    NEW_BUILD=""
    NEW_COMMIT=""
    NEW_ZADARK=""
  else
    UPDATE_NEEDED=true
  fi
fi

if [ "$APPLY" = "--apply" ] && [ "$UPDATE_NEEDED" = "true" ]; then
  if [ "$LATEST" != "$CURRENT" ]; then
    sed -i "s/^pkgver=.*/pkgver=${LATEST}/" "${PKG_DIR}/PKGBUILD"
    sed -i "s/^pkgrel=.*/pkgrel=1/" "${PKG_DIR}/PKGBUILD"
  else
    # Same pkgver but a new upstream build/commit: bump pkgrel so the package
    # filename changes, otherwise CI sees it as already published and skips it.
    CURRENT_REL=$(grep -oP '^pkgrel=\K[0-9]+' "${PKG_DIR}/PKGBUILD" | head -1)
    sed -i "s/^pkgrel=.*/pkgrel=$((CURRENT_REL + 1))/" "${PKG_DIR}/PKGBUILD"
  fi
  if [ -n "$NEW_BUILD" ] && [[ "$NEW_BUILD" =~ ^[0-9A-Za-z._+]+$ ]]; then
    sed -i "s/^_build=.*/_build=${NEW_BUILD}/" "${PKG_DIR}/PKGBUILD"
  fi
  if [ -n "$NEW_COMMIT" ] && [[ "$NEW_COMMIT" =~ ^[0-9a-fA-F]+$ ]]; then
    sed -i "s/^_commithash=.*/_commithash=${NEW_COMMIT}/" "${PKG_DIR}/PKGBUILD"
  fi
  if [ -n "${NEW_ZADARK:-}" ] && [[ "$NEW_ZADARK" =~ ^[0-9.]+$ ]]; then
    sed -i "s/^_zadarkver=.*/_zadarkver=${NEW_ZADARK}/" "${PKG_DIR}/PKGBUILD"
  fi
fi

# Output results in key=value format
echo "PKG=${PKG}"
echo "CURRENT=${CURRENT}"
echo "LATEST=${LATEST}"
echo "UPDATE_NEEDED=${UPDATE_NEEDED}"
echo "EXTRA_INFO=${EXTRA_INFO}"
