#!/bin/bash
# Prevent Electron/AppImage from creating unmanaged desktop files in ~/.local/share/applications
export DESKTOPINTEGRATION=0

# Clean rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/antigravity.desktop" \
      "$HOME/.local/share/applications/Antigravity.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/antigravity-flags.conf"
SYSTEM_FLAGS_FILE="/etc/antigravity-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/antigravity-flags.conf, fallback to system config /etc/antigravity-flags.conf
if [[ -f "$USER_FLAGS_FILE" ]]; then
    CONFIG_FILE="$USER_FLAGS_FILE"
elif [[ -f "$SYSTEM_FLAGS_FILE" ]]; then
    CONFIG_FILE="$SYSTEM_FLAGS_FILE"
else
    CONFIG_FILE=""
fi

if [[ -n "$CONFIG_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        FLAGS+=("$line")
    done < "$CONFIG_FILE"
else
    # Default Wayland flags if no config file exists
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
    fi
fi

exec /opt/antigravity/antigravity "${FLAGS[@]}" "$@"
