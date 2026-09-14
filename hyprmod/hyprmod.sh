#!/usr/bin/env bash
set -eo pipefail

# Disable AppImage runtime desktop integration if invoked in that context
export DESKTOPINTEGRATION=0

# Clean any rogue user desktop files from legacy/pipx installs
rm -f "$HOME/.local/share/applications/hyprmod.desktop" \
      "$HOME/.local/share/applications/io.github.bluemancz.hyprmod.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/hyprmod-flags.conf"
SYSTEM_FLAGS_FILE="/etc/hyprmod-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/hyprmod-flags.conf, fallback to system config /etc/hyprmod-flags.conf
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
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            export "$line"
        else
            FLAGS+=("$line")
        fi
    done < "$CONFIG_FILE"
fi

exec /usr/lib/hyprmod/hyprmod "${FLAGS[@]}" "$@"
