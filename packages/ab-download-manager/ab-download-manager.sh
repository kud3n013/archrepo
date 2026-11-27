#!/bin/bash
# Launcher for AB Download Manager.
#
# Reads ~/.config/ab-download-manager-flags.conf, falling back to
# /etc/ab-download-manager-flags.conf. KEY=VALUE lines are exported unless the
# variable is already set in the environment, so a one-off
# `SKIKO_RENDER_API=OPENGL ab-download-manager` still wins. Other lines are
# passed to the app as arguments.

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/ab-download-manager-flags.conf"
SYSTEM_FLAGS_FILE="/etc/ab-download-manager-flags.conf"

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
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            [[ -v "${BASH_REMATCH[1]}" ]] || export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
        else
            FLAGS+=("$line")
        fi
    done < "$CONFIG_FILE"
fi

# Skia's OpenGL backend draws a black window on many Wayland/XWayland and
# NVIDIA setups; software rendering works everywhere. Kept as a fallback for
# a user flags file that does not set it.
export SKIKO_RENDER_API="${SKIKO_RENDER_API:-SOFTWARE}"

exec /opt/ab-download-manager/bin/ABDownloadManager "${FLAGS[@]}" "$@"
