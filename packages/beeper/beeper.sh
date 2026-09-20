#!/bin/bash
# Prevent Electron/AppImage from creating unmanaged desktop files in ~/.local/share/applications
export DESKTOPINTEGRATION=0

# Enforce desktop file remoting / identity mapping
export CHROME_DESKTOP="${CHROME_DESKTOP:-beeper.desktop}"

# Clean rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/Beeper.desktop" \
      "$HOME/.local/share/applications/beeper.desktop" \
      "$HOME/.local/share/applications/beepertexts.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/beeper-flags.conf"
SYSTEM_FLAGS_FILE="/etc/beeper-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/beeper-flags.conf, fallback to system config /etc/beeper-flags.conf
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
        # On native Wayland where Global Menu cannot be mapped, keep menu accessible in-window
        export ELECTRON_FORCE_WINDOW_MENU_BAR="${ELECTRON_FORCE_WINDOW_MENU_BAR:-1}"
    fi
fi

# Under X11 (or XWayland), GTK loads appmenu-gtk-module from XSETTINGS on KDE Plasma.
# Electron unloads GTK via dlclose(), but libappmenu-gtk-module does not unregister
# its GIO D-Bus name watcher on unload, triggering a SIGSEGV when D-Bus replies into unmapped memory.
# Preloading libappmenu-gtk-module.so pins it in memory and prevents the crash.
if [[ -f "/usr/lib/gtk-3.0/modules/libappmenu-gtk-module.so" ]]; then
    export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}/usr/lib/gtk-3.0/modules/libappmenu-gtk-module.so"
fi

exec /opt/beeper/AppRun --no-sandbox "${DEFAULT_PLATFORM_FLAGS[@]}" "${ALL_ARGS[@]}"
