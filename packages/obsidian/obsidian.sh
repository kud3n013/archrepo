#!/bin/bash
# Disable AppImage runtime desktop integration if any
export DESKTOPINTEGRATION=0

# If invoked with known Obsidian CLI subcommands, pass directly to the bundled obsidian-cli
case "$1" in
    version|vault|open|create|search|wordcount|workspace|workspaces|tabs|recents|devtools|dev:*|eval|help)
        exec /opt/Obsidian/obsidian-cli "$@"
        ;;
esac

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/obsidian-flags.conf"
SYSTEM_FLAGS_FILE="/etc/obsidian-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/obsidian-flags.conf, fallback to system config /etc/obsidian-flags.conf
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

exec /opt/Obsidian/obsidian "${FLAGS[@]}" "$@"
