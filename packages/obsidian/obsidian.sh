#!/bin/bash
# Disable AppImage runtime desktop integration if any
export DESKTOPINTEGRATION=0

# Enforce desktop file identity mapping
export CHROME_DESKTOP="${CHROME_DESKTOP:-obsidian.desktop}"

# If invoked with known Obsidian CLI subcommands, pass directly to the bundled obsidian-cli
case "$1" in
    version|vault|open|create|search|wordcount|workspace|workspaces|tabs|recents|devtools|dev:*|eval|help)
        exec /opt/Obsidian/obsidian-cli "$@"
        ;;
esac

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/obsidian-flags.conf"
SYSTEM_FLAGS_FILE="/etc/obsidian-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/obsidian-flags.conf, fallback to system config /etc/obsidian-flags.conf
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

# Under X11 (or XWayland), GTK loads modules specified in XSETTINGS (e.g. appmenu-gtk-module,
# colorreload-gtk-module, window-decorations-gtk-module) on KDE Plasma.
# When Electron unloads GTK via dlclose(), these modules are unmapped from memory while their
# background GIO file monitors and D-Bus callbacks remain registered.
# This causes an immediate SIGSEGV (SEGV_ACCERR) when GIO iterations run on KDE theme switch.
# Pin all installed GTK3 modules into memory via LD_PRELOAD to prevent dlclose() from unmapping them.
for _mod in /usr/lib/gtk-3.0/modules/*.so; do
    if [[ -f "$_mod" ]]; then
        export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$_mod"
    fi
done

# Enable Global Menu shortcut bridge for KDE Plasma / Qt appmenu (restores punctuation shortcut tips like Ctrl+,)
if [[ -f "/opt/Obsidian/libobsidian-globalmenu.so" ]]; then
    export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}/opt/Obsidian/libobsidian-globalmenu.so"
fi

exec /opt/Obsidian/obsidian "${DEFAULT_PLATFORM_FLAGS[@]}" "${ALL_ARGS[@]}"
