#!/usr/bin/env bash
set -euo pipefail

# tools/scaffold.sh: Scaffolds a standard package template in packages/<pkgname>.
# Usage: ./tools/scaffold.sh <package-name> [upstream-github-repo]

PKG_NAME="${1:-}"
UPSTREAM_REPO="${2:-}"

if [ -z "$PKG_NAME" ]; then
  echo "Usage: $0 <package-name> [upstream-github-repo]"
  echo "Example: $0 my-app owner/repo"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${REPO_DIR}/packages/${PKG_NAME}"

if [ -d "$TARGET_DIR" ]; then
  echo "Error: Package directory '${TARGET_DIR}' already exists." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

# 1. PKGBUILD skeleton
cat << PKG_EOF > "${TARGET_DIR}/PKGBUILD"
# Maintainer: kud3n013 <kud3n.013@proton.me>
pkgname=${PKG_NAME}
pkgver=1.0.0
pkgrel=1
pkgdesc="${PKG_NAME} application"
arch=('x86_64')
url="https://github.com/${UPSTREAM_REPO:-owner/repo}"
license=('custom')
depends=('gtk3' 'nss' 'alsa-lib')
provides=("${PKG_NAME}-bin")
conflicts=("${PKG_NAME}-bin")
options=('!strip' '!debug')
backup=("etc/${PKG_NAME}-flags.conf")
install=${PKG_NAME}.install
source=(
  "${PKG_NAME}.sh"
  "${PKG_NAME}-flags.conf"
  "${PKG_NAME}.desktop"
)
sha256sums=(
  'SKIP'
  'SKIP'
  'SKIP'
)

package() {
  install -Dm755 "\${srcdir}/${PKG_NAME}.sh" "\${pkgdir}/usr/bin/${PKG_NAME}"
  install -Dm644 "\${srcdir}/${PKG_NAME}-flags.conf" "\${pkgdir}/etc/${PKG_NAME}-flags.conf"
  install -Dm644 "\${srcdir}/${PKG_NAME}.desktop" "\${pkgdir}/usr/share/applications/${PKG_NAME}.desktop"
}
PKG_EOF

# 2. upstream.json
if [ -n "$UPSTREAM_REPO" ]; then
  cat << UP_EOF > "${TARGET_DIR}/upstream.json"
{
  "check": "github-release",
  "repo": "${UPSTREAM_REPO}"
}
UP_EOF
else
  cat << UP_EOF > "${TARGET_DIR}/upstream.json"
{
  "check": "none"
}
UP_EOF
fi

# 3. launcher script
cat << SH_EOF > "${TARGET_DIR}/${PKG_NAME}.sh"
#!/bin/bash
export DESKTOPINTEGRATION=0

# Clean rogue desktop files
rm -f "\$HOME/.local/share/applications/${PKG_NAME}.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="\${XDG_CONFIG_HOME:-\$HOME/.config}"
USER_FLAGS_FILE="\$XDG_CONFIG_HOME/${PKG_NAME}-flags.conf"
SYSTEM_FLAGS_FILE="/etc/${PKG_NAME}-flags.conf"

FLAGS=()
if [[ -f "\$USER_FLAGS_FILE" ]]; then
    CONFIG_FILE="\$USER_FLAGS_FILE"
elif [[ -f "\$SYSTEM_FLAGS_FILE" ]]; then
    CONFIG_FILE="\$SYSTEM_FLAGS_FILE"
else
    CONFIG_FILE=""
fi

if [[ -n "\$CONFIG_FILE" ]]; then
    while IFS= read -r line || [[ -n "\$line" ]]; do
        line="\$(echo "\$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -z "\$line" || "\$line" =~ ^# ]] && continue
        FLAGS+=("\$line")
    done < "\$CONFIG_FILE"
else
    if [[ -n "\$WAYLAND_DISPLAY" ]]; then
        FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
    fi
fi

exec /opt/${PKG_NAME}/${PKG_NAME} "\${FLAGS[@]}" "\$@"
SH_EOF
chmod +x "${TARGET_DIR}/${PKG_NAME}.sh"

# 4. flags file
cat << CONF_EOF > "${TARGET_DIR}/${PKG_NAME}-flags.conf"
# Configuration flags for ${PKG_NAME}
# Uncomment or add flags below:
# --ozone-platform-hint=auto
# --enable-wayland-ime
CONF_EOF

# 5. install scriptlet
cat << INST_EOF > "${TARGET_DIR}/${PKG_NAME}.install"
_cleanup_user_desktops() {
    for user_home in /home/*; do
        if [ -d "\$user_home/.local/share/applications" ]; then
            rm -f "\$user_home/.local/share/applications/${PKG_NAME}.desktop" 2>/dev/null || true
        fi
    done
}

post_install() {
    _cleanup_user_desktops
    update-desktop-database -q 2>/dev/null || true
}

post_upgrade() {
    post_install
}

post_remove() {
    _cleanup_user_desktops
    update-desktop-database -q 2>/dev/null || true
}
INST_EOF

# 6. desktop entry
cat << DT_EOF > "${TARGET_DIR}/${PKG_NAME}.desktop"
[Desktop Entry]
Name=${PKG_NAME}
Comment=${PKG_NAME} application
Exec=${PKG_NAME} %U
Icon=${PKG_NAME}
Type=Application
Categories=Utility;
StartupWMClass=${PKG_NAME}
DT_EOF

echo "Scaffolded package skeleton in packages/${PKG_NAME} successfully."
