#!/bin/bash
# Disable AppImage runtime desktop integration if any
export DESKTOPINTEGRATION=0

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/freedownloadmanager-flags.conf"
SYSTEM_FLAGS_FILE="/etc/freedownloadmanager-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/freedownloadmanager-flags.conf, fallback to system config /etc/freedownloadmanager-flags.conf
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
else
    # Default Wayland flags if no config file exists
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
    fi
fi

# Automatically link system-wide FDM plugins if present
SYSTEM_PLUGINS_DIR="/usr/share/freedownloadmanager/plugins"
if [[ -d "$SYSTEM_PLUGINS_DIR" ]]; then
    USER_PLUGINS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/Softdeluxe/Free Download Manager/plugins"
    mkdir -p "$USER_PLUGINS_DIR"
    # Clean up broken plugin symlinks
    for link in "$USER_PLUGINS_DIR"/*; do
        if [[ -L "$link" && ! -e "$link" ]]; then
            rm -f "$link"
        fi
    done
    # Symlink system plugins
    for plugin in "$SYSTEM_PLUGINS_DIR"/*; do
        [[ -d "$plugin" ]] || continue
        plugin_name="$(basename "$plugin")"
        if [[ ! -e "$USER_PLUGINS_DIR/$plugin_name" ]]; then
            ln -s "$plugin" "$USER_PLUGINS_DIR/$plugin_name"
        fi
    done
fi

exec /opt/freedownloadmanager/fdm "${FLAGS[@]}" "$@"
