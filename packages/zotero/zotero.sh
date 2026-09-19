#!/bin/bash
# Launcher wrapper for Zotero (kud3n013/archrepo)
# Restores native window titlebar, KDE Global Menu, and dynamic GTK/Qt theme selection

# Disable AppImage / runtime desktop integration if any
export DESKTOPINTEGRATION=0

# Clean any rogue user desktop files on launch
rm -f "$HOME/.local/share/applications/zotero.desktop" \
      "$HOME/.local/share/applications/Zotero.desktop" 2>/dev/null || true

# Increase open files limit (per upstream recommendation for translators & styles)
ulimit -n 4096 2>/dev/null || true

# Mozilla ESR profile settings
export MOZ_ALLOW_DOWNGRADE="${MOZ_ALLOW_DOWNGRADE:-1}"
export MOZ_LEGACY_PROFILES="${MOZ_LEGACY_PROFILES:-1}"

# Load user configuration flags
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/zotero-flags.conf"
SYSTEM_FLAGS_FILE="/etc/zotero-flags.conf"

FLAGS=()

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
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
        else
            FLAGS+=("$line")
        fi
    done < "$CONFIG_FILE"
fi

# Enable native Wayland backend under Wayland compositors
if [[ -n "$WAYLAND_DISPLAY" ]]; then
    export MOZ_ENABLE_WAYLAND="${MOZ_ENABLE_WAYLAND:-1}"
fi

# ==============================================================================
# Dynamic Desktop Environment & Theme Selection (Hyprland GTK vs KDE Qt)
# ==============================================================================
CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-}"

# Check if running under KDE Plasma (or explicitly forced)
if [[ "${ZOTERO_DESKTOP_ENV,,}" == "kde" ]] || [[ "$CURRENT_DESKTOP" =~ [Kk][Dd][Ee]|plasma|Plasma ]]; then
    export ZOTERO_DESKTOP_ENV="kde"
    export GTK_USE_PORTAL="${GTK_USE_PORTAL:-1}"

    # Match KDE color scheme with Qt/Breeze theme if GTK_THEME is not explicitly overridden
    if [[ -z "$GTK_THEME" ]]; then
        KDE_COLOR=$(kreadconfig6 --group General --key ColorScheme 2>/dev/null || \
                   kreadconfig5 --group General --key ColorScheme 2>/dev/null || true)
        if [[ "$KDE_COLOR" =~ [Dd]ark|[Bb]lack ]] || [[ -f "$HOME/.config/kdeglobals" && $(grep -i "ColorScheme.*Dark" "$HOME/.config/kdeglobals" 2>/dev/null) ]]; then
            export GTK_THEME="Breeze-Dark"
        else
            export GTK_THEME="Breeze"
        fi
    fi

    # Load AppMenu GTK module for KDE Global Menu if installed on system
    if [[ -f "/usr/lib/gtk-3.0/modules/libappmenu-gtk-module.so" ]]; then
        if [[ -z "$GTK_MODULES" ]]; then
            export GTK_MODULES="appmenu-gtk-module"
        elif [[ "$GTK_MODULES" != *"appmenu-gtk-module"* ]]; then
            export GTK_MODULES="${GTK_MODULES}:appmenu-gtk-module"
        fi
    fi

# Check if running under Hyprland (or explicitly forced)
elif [[ "${ZOTERO_DESKTOP_ENV,,}" == "hyprland" ]] || [[ "$CURRENT_DESKTOP" =~ [Hh]yprland|HYPRLAND ]]; then
    export ZOTERO_DESKTOP_ENV="hyprland"
    export GTK_USE_PORTAL="${GTK_USE_PORTAL:-1}"
    # Default menubar mode on Hyprland: 'autohide' (revealed by Alt or F10, or toggled with Ctrl+M)
    export ZOTERO_MENUBAR="${ZOTERO_MENUBAR:-autohide}"
    # GTK theme automatically follows user's gsettings / nwg-look settings
else
    # Default fallback for other desktop environments (GNOME, Sway, XFCE, etc.)
    export GTK_USE_PORTAL="${GTK_USE_PORTAL:-1}"
    export ZOTERO_MENUBAR="${ZOTERO_MENUBAR:-autohide}"
fi

exec /usr/lib/zotero/zotero-bin -app /usr/lib/zotero/app/application.ini "${FLAGS[@]}" "$@"
