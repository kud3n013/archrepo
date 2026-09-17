#!/usr/bin/env bash
# Launcher wrapper script for Galaxy Buds Manager (Avalonia .NET)
set -e

# Prevent rogue desktop files from runtime desktop integration
export DESKTOPINTEGRATION=0

# Clean any rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/galaxybudsclient.desktop" \
      "$HOME/.local/share/applications/GalaxyBudsClient.desktop" \
      "$HOME/.local/share/applications/Galaxy Buds Manager.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/galaxybudsclient-flags.conf"
SYSTEM_FLAGS_FILE="/etc/galaxybudsclient-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/galaxybudsclient-flags.conf, fallback to system config
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

        # Handle environment variable exports (KEY=VALUE)
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
        else
            FLAGS+=("$line")
        fi
    done < "$CONFIG_FILE"
fi

exec /opt/galaxybudsclient/GalaxyBudsClient "${FLAGS[@]}" "$@"
