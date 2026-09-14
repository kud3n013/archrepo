#!/bin/bash
# Disable AppImage runtime desktop integration if any
export DESKTOPINTEGRATION=0

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/proton-pass-flags.conf"
SYSTEM_FLAGS_FILE="/etc/proton-pass-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/proton-pass-flags.conf, fallback to system config /etc/proton-pass-flags.conf
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

exec "/opt/proton-pass/Proton Pass" "${FLAGS[@]}" "$@"
