#!/bin/bash
# Launcher wrapper for Zen Browser (Firefox-based)
# Prevent rogue desktop file creation
export DESKTOPINTEGRATION=0

# Clean any rogue user desktop files on launch
rm -f "$HOME/.local/share/applications/zen-browser.desktop" \
      "$HOME/.local/share/applications/zen.desktop" \
      "$HOME/.local/share/applications/Zen Browser.desktop" \
      "$HOME/.local/share/applications/Zen.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/zen-browser-flags.conf"
SYSTEM_FLAGS_FILE="/etc/zen-browser-flags.conf"

FLAGS=()

# Prefer user configuration, fallback to system config
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
        if [[ "$line" =~ ^([A-Z_][A-Z0-9_]*)=(.*)$ ]]; then
            export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
        else
            FLAGS+=("$line")
        fi
    done < "$CONFIG_FILE"
else
    # Default: enable native Wayland if running under a Wayland compositor
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        export MOZ_ENABLE_WAYLAND=1
    fi
fi

exec /opt/zen-browser/zen-bin "${FLAGS[@]}" "$@"
