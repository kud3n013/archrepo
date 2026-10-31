#!/bin/bash
# Launcher for Triggers Client, installed as /usr/bin/triggers-client.
# The real binary is /opt/triggers-client/triggers-client.

# Flags: the user file wins over the system file, the same as the other wrappers.
# Triggers Client is a Tauri (WebKitGTK) app, not Electron, so Chromium switches
# do nothing; KEY=VALUE lines are exported as environment variables and any other
# line is passed to the app as an argument.
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/triggers-client-flags.conf"
SYSTEM_FLAGS_FILE="/etc/triggers-client-flags.conf"

if [[ -f "$USER_FLAGS_FILE" ]]; then
    CONFIG_FILE="$USER_FLAGS_FILE"
elif [[ -f "$SYSTEM_FLAGS_FILE" ]]; then
    CONFIG_FILE="$SYSTEM_FLAGS_FILE"
else
    CONFIG_FILE=""
fi

FLAGS=()
if [[ -n "$CONFIG_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            # shellcheck disable=SC2163  # exports the KEY=VALUE pair the line holds
            export "$line"
        else
            FLAGS+=("$line")
        fi
    done < "$CONFIG_FILE"
fi

exec /opt/triggers-client/triggers-client "${FLAGS[@]}" "$@"
