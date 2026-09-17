#!/bin/bash
# Prevent Electron/AppImage from creating unmanaged desktop files in ~/.local/share/applications
export DESKTOPINTEGRATION=0

# Clean any rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/gdlauncher-carbon.desktop" \
      "$HOME/.local/share/applications/GDLauncher Carbon.desktop" \
      "$HOME/.local/share/applications/GDLauncher-Carbon.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/gdlauncher-carbon-flags.conf"
SYSTEM_FLAGS_FILE="/etc/gdlauncher-carbon-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/gdlauncher-carbon-flags.conf, fallback to system config
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

exec /opt/gdlauncher-carbon/AppRun --no-sandbox "${FLAGS[@]}" "$@"
