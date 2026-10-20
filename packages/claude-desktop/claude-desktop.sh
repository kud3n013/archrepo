#!/bin/bash
# Launcher for Claude Desktop, installed as /usr/bin/claude-desktop.
# The real binary is /opt/claude-desktop/claude-desktop.

# Stop the launcher from writing per-user desktop files. The app manages its own
# launcher entry (see claude-desktop.install).
export DESKTOPINTEGRATION=0

# Electron uses this to match the window to its desktop entry on Wayland.
export CHROME_DESKTOP="${CHROME_DESKTOP:-com.anthropic.Claude.desktop}"

# Flags: the user file wins over the system file, the same as the other wrappers.
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/claude-desktop-flags.conf"
SYSTEM_FLAGS_FILE="/etc/claude-desktop-flags.conf"

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
        # Trim surrounding whitespace: Chromium ignores a switch with a leading space.
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        FLAGS+=("$line")
    done < "$CONFIG_FILE"
fi

# Default to native Wayland when no platform was chosen explicitly. Without this
# Electron runs under XWayland, which is blurry on scaled displays. Quick Entry's
# GlobalShortcuts portal is already enabled by the app itself, so it needs no flag.
HAS_OZONE=false
for arg in "${FLAGS[@]}" "$@"; do
    if [[ "$arg" == --ozone-platform* ]]; then
        HAS_OZONE=true
        break
    fi
done

PLATFORM_FLAGS=()
if [[ "$HAS_OZONE" == false && ( -n "$WAYLAND_DISPLAY" || "$XDG_SESSION_TYPE" == wayland ) ]]; then
    PLATFORM_FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
fi

exec /opt/claude-desktop/claude-desktop "${PLATFORM_FLAGS[@]}" "${FLAGS[@]}" "$@"
