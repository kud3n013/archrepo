#!/bin/bash
# Prevent Electron/AppImage from creating unmanaged desktop files in ~/.local/share/applications
export DESKTOPINTEGRATION=0

# Clean rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/antigravity.desktop" \
      "$HOME/.local/share/applications/Antigravity.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/antigravity-flags.conf"
SYSTEM_FLAGS_FILE="/etc/antigravity-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/antigravity-flags.conf, fallback to system config /etc/antigravity-flags.conf
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
fi

ALL_ARGS=("${FLAGS[@]}" "$@")

# Check if user specified ozone platform explicitly
HAS_OZONE=false
for arg in "${ALL_ARGS[@]}"; do
    if [[ "$arg" =~ ^--ozone-platform ]]; then
        HAS_OZONE=true
        break
    fi
done

# If no ozone platform specified and running under Wayland:
# On KDE Plasma, run via XWayland (--ozone-platform=x11) so KWin can associate
# the DBus menu with the window and display it in the KDE Global Menu widget.
# On other Wayland compositors (Hyprland, Sway, GNOME, etc.), default to native Wayland.
DEFAULT_PLATFORM_FLAGS=()
if [[ "$HAS_OZONE" == false && -n "$WAYLAND_DISPLAY" ]]; then
    if [[ "$XDG_CURRENT_DESKTOP" =~ [Kk][Dd][Ee]|plasma|Plasma ]] || [[ "$KDE_FULL_SESSION" == "true" ]]; then
        DEFAULT_PLATFORM_FLAGS+=("--ozone-platform=x11")
    else
        DEFAULT_PLATFORM_FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
    fi
fi

# Process titlebar and menubar flags from config file and CLI arguments
FINAL_FLAGS=("${DEFAULT_PLATFORM_FLAGS[@]}")
for arg in "${ALL_ARGS[@]}"; do
    case "$arg" in
        --titlebar=hidden|--no-window-controls|--hide-window-controls)
            export ANTIGRAVITY_TITLEBAR="hidden"
            ;;
        --titlebar=native|--titlebar=system)
            export ANTIGRAVITY_TITLEBAR="native"
            ;;
        --titlebar=overlay)
            export ANTIGRAVITY_TITLEBAR="overlay"
            ;;
        --menubar=autohide|--menubar=hidden|--hide-menubar|--no-menubar)
            # Menubar autohide is enabled by default in patched build
            ;;
        *)
            FINAL_FLAGS+=("$arg")
            ;;
    esac
done

exec /opt/antigravity/antigravity "${FINAL_FLAGS[@]}"
