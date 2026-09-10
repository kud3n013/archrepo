#!/bin/bash
# Prevent AppImage from writing unmanaged desktop files to ~/.local/share/applications
export DESKTOPINTEGRATION=0

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/zalo-flags.conf"
SYSTEM_FLAGS_FILE="/etc/zalo-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/zalo-flags.conf, fallback to system config /etc/zalo-flags.conf
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
        if [[ "$line" =~ ^(export[[:space:]]+)?ZCALL_DISABLE=1 ]]; then
            export ZCALL_DISABLE=1
            continue
        fi
        FLAGS+=("$line")
    done < "$CONFIG_FILE"
else
    # Default Wayland flags if no config file exists
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
    fi
fi

export LD_LIBRARY_PATH="/opt/zalo-for-linux/usr/lib:${LD_LIBRARY_PATH}"
export GSETTINGS_SCHEMA_DIR="/opt/zalo-for-linux/usr/share/glib-2.0/schemas:${GSETTINGS_SCHEMA_DIR}"

exec /opt/zalo-for-linux/zalo "${FLAGS[@]}" "$@"
