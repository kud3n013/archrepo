#!/bin/bash
# Prevent desktop integration collisions
export DESKTOPINTEGRATION=0

# Clean rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/Stirling PDF.desktop" \
      "$HOME/.local/share/applications/Stirling-PDF.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/stirling-pdf-desktop-flags.conf"
SYSTEM_FLAGS_FILE="/etc/stirling-pdf-desktop-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/stirling-pdf-desktop-flags.conf, fallback to /etc/stirling-pdf-desktop-flags.conf
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
fi

# WebKitGTK DMA-BUF renderer and NVIDIA explicit sync crash mitigation
export WEBKIT_DISABLE_DMABUF_RENDERER="${WEBKIT_DISABLE_DMABUF_RENDERER:-1}"
export __NV_DISABLE_EXPLICIT_SYNC="${__NV_DISABLE_EXPLICIT_SYNC:-1}"

# KDE Plasma & Window Decoration Integration:
# On KDE Plasma, GTK3 defaults to Client-Side Decorations (CSD) with GNOME/GTK styling under Wayland.
# To make the title bar use the KDE Qt theme (Breeze/KWin window decoration):
# 1. By default on KDE Plasma, run via XWayland (GDK_BACKEND=x11) so KWin draws Server-Side Decorations (SSD)
#    matching the system-wide KDE Qt theme (Breeze, Oxygen, Klassy, etc.) with exact native buttons and layout.
# 2. If the user explicitly configures GDK_BACKEND=wayland, fall back to applying the Breeze GTK theme
#    and KDE window decoration modules to align CSD with the KDE Qt appearance.
IS_KDE=false
if [[ "$XDG_CURRENT_DESKTOP" =~ [Kk][Dd][Ee]|plasma|Plasma ]] || [[ "$KDE_FULL_SESSION" == "true" ]]; then
    IS_KDE=true
fi

if [[ "$IS_KDE" == true ]]; then
    if [[ -z "$GDK_BACKEND" ]]; then
        # Default to X11 on KDE to force KWin native Qt window decorations (Server-Side Decorations)
        export GDK_BACKEND="x11"
    elif [[ "$GDK_BACKEND" == "wayland" ]]; then
        # If user explicitly opted into Wayland backend, match KDE Breeze styling for GTK CSD titlebar
        if [[ -z "$GTK_THEME" ]]; then
            IS_DARK=false
            if command -v kreadconfig6 &>/dev/null; then
                COLOR_SCHEME=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)
                if [[ "$COLOR_SCHEME" =~ [Dd]ark ]]; then
                    IS_DARK=true
                fi
            elif command -v gsettings &>/dev/null; then
                if [[ "$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)" =~ prefer-dark ]]; then
                    IS_DARK=true
                fi
            fi

            if [[ "$IS_DARK" == true ]]; then
                export GTK_THEME="Breeze-Dark"
            else
                export GTK_THEME="Breeze"
            fi
        fi

        # Load KDE window decorations GTK modules if present
        for _mod in colorreload-gtk-module window-decorations-gtk-module; do
            if [[ -f "/usr/lib/gtk-3.0/modules/lib${_mod}.so" ]]; then
                export GTK_MODULES="${GTK_MODULES:+${GTK_MODULES}:}${_mod}"
            fi
        done
    fi
fi

# Pin installed GTK3 modules into memory via LD_PRELOAD to prevent dlclose() crashes during theme reloads
for _mod in /usr/lib/gtk-3.0/modules/*.so; do
    if [[ -f "$_mod" ]]; then
        export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$_mod"
    fi
done

exec "/usr/lib/Stirling PDF/Stirling-PDF" "${FLAGS[@]}" "$@"
