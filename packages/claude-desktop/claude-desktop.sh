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

# Default to native Wayland when no platform was chosen explicitly (KDE is the
# exception, see below). Without this Electron runs under XWayland, which is
# blurry on scaled displays. Quick Entry's GlobalShortcuts portal is already
# enabled by the app itself, so it needs no flag.
HAS_OZONE=false
OZONE_X11=false
for arg in "${FLAGS[@]}" "$@"; do
    if [[ "$arg" == --ozone-platform* ]]; then
        HAS_OZONE=true
        [[ "$arg" == --ozone-platform=x11 ]] && OZONE_X11=true
    fi
done

# KDE Plasma Global Menu. On native Wayland, Electron exports the menu over D-Bus
# but nothing binds it to the window, so Plasma shows no menu (Electron PR #54629
# is open for this). Under XWayland the window has an X id that the Plasma
# registrar can match, so on KDE the app runs under XWayland. Set
# CLAUDE_DESKTOP_GLOBALMENU=0 to keep native Wayland and lose the Global Menu.
IS_KDE=false
if [[ "$XDG_CURRENT_DESKTOP" =~ [Kk][Dd][Ee]|[Pp]lasma ]] || [[ "$KDE_FULL_SESSION" == "true" ]]; then
    IS_KDE=true
fi

USE_GLOBALMENU_X11=false
PLATFORM_FLAGS=()
if [[ "$HAS_OZONE" == false && ( -n "$WAYLAND_DISPLAY" || "$XDG_SESSION_TYPE" == wayland ) ]]; then
    if [[ "$IS_KDE" == true && "${CLAUDE_DESKTOP_GLOBALMENU:-1}" != 0 ]]; then
        USE_GLOBALMENU_X11=true
        PLATFORM_FLAGS+=("--ozone-platform=x11")
    else
        PLATFORM_FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
    fi
fi

# Under XWayland, GTK loads the modules set in XSETTINGS (appmenu-gtk-module,
# colorreload-gtk-module, ...). Electron unloads GTK with dlclose(), which unmaps
# those modules while their GIO monitors and D-Bus callbacks stay registered, and
# the next GIO callback crashes (SIGSEGV, SEGV_ACCERR). Pin the GTK3 modules into
# memory so dlclose() cannot unmap them. The app follows theme changes live (see
# theme-sync.js), so every X11 run needs this: the Global Menu path above, an
# --ozone-platform=x11 flag, or an X11 session. Native Wayland is left alone.
if [[ "$USE_GLOBALMENU_X11" == true || "$OZONE_X11" == true ]] ||
   [[ "$HAS_OZONE" == false && -z "$WAYLAND_DISPLAY" && "$XDG_SESSION_TYPE" != wayland ]]; then
    for _mod in /usr/lib/gtk-3.0/modules/*.so; do
        if [[ -f "$_mod" ]]; then
            export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$_mod"
        fi
    done
fi

exec /opt/claude-desktop/claude-desktop "${PLATFORM_FLAGS[@]}" "${FLAGS[@]}" "$@"
