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

# On Wayland, Electron lacks native org_kde_kwin_appmenu Wayland protocol support.
# On KDE Plasma, run via XWayland (--ozone-platform=x11) so KWin can associate
# the DBus menu with the window and display it in the KDE Global Menu widget.
# On other Wayland compositors (Hyprland, Sway, GNOME, etc.), default to native Wayland.
DEFAULT_PLATFORM_FLAGS=()
IS_KDE=false
if [[ "$XDG_CURRENT_DESKTOP" =~ [Kk][Dd][Ee]|plasma|Plasma ]] || [[ "$KDE_FULL_SESSION" == "true" ]]; then
    IS_KDE=true
fi

if [[ "$HAS_OZONE" == false && -n "$WAYLAND_DISPLAY" ]]; then
    if [[ "$IS_KDE" == true ]]; then
        DEFAULT_PLATFORM_FLAGS+=("--ozone-platform=x11")
    else
        DEFAULT_PLATFORM_FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
    fi
fi

# Under X11 (or XWayland), GTK loads modules specified in XSETTINGS (e.g. appmenu-gtk-module,
# colorreload-gtk-module, window-decorations-gtk-module) on KDE Plasma.
# When Electron unloads GTK via dlclose(), these modules are unmapped from memory while their
# background GIO file monitors and D-Bus callbacks remain registered.
# This causes an immediate SIGSEGV (SEGV_ACCERR) when GIO iterations run.
# Pin all installed GTK3 modules into memory via LD_PRELOAD to prevent dlclose() from unmapping them.
for _mod in /usr/lib/gtk-3.0/modules/*.so; do
    if [[ -f "$_mod" ]]; then
        export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$_mod"
    fi
done

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
        --menubar=in-app|--menubar=web)
            export ANTIGRAVITY_MENUBAR="in-app"
            ;;
        --menubar=native|--menubar=system|--menubar=autohide|--menubar=hidden|--hide-menubar|--no-menubar)
            export ANTIGRAVITY_MENUBAR="native"
            ;;
        *)
            FINAL_FLAGS+=("$arg")
            ;;
    esac
done

exec /opt/antigravity/antigravity "${FINAL_FLAGS[@]}"
