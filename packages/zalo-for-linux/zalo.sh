#!/bin/bash
# Launcher for Zalo, installed as /usr/bin/zalo.
# The real binary is /opt/zalo-for-linux/zalo, run against the system libraries.

# Stop the launcher from writing per-user desktop files (see zalo-for-linux.install).
export DESKTOPINTEGRATION=0

# Electron uses this to match the window to its desktop entry.
export CHROME_DESKTOP="${CHROME_DESKTOP:-zalo.desktop}"

# Flags: the user file wins over the system file, the same as the other wrappers.
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/zalo-flags.conf"
SYSTEM_FLAGS_FILE="/etc/zalo-flags.conf"

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

# An explicit --ozone-platform* flag, from the flags file or the command line, wins.
OZONE=""
for arg in "${FLAGS[@]}" "$@"; do
    if [[ "$arg" == --ozone-platform* ]]; then
        OZONE="$arg"
        break
    fi
done

IS_KDE=false
if [[ "$XDG_CURRENT_DESKTOP" =~ [Kk][Dd][Ee]|[Pp]lasma ]] || [[ "$KDE_FULL_SESSION" == "true" ]]; then
    IS_KDE=true
fi

# Zalo bundles Electron 22. On native Wayland it gets no window decorations (upstream's
# plugins/wayland-titlebar adds buttons to the page instead) and no Global Menu (Electron
# exports the menu, but nothing binds it to a Wayland window). On KDE Plasma the app runs
# under XWayland, where KWin draws the title bar and the Plasma registrar binds the menu.
# Other Wayland compositors get native Wayland with upstream's in-page buttons.
PLATFORM_FLAGS=()
USE_X11=false
if [[ -n "$OZONE" ]]; then
    [[ "$OZONE" == --ozone-platform=x11 ]] && USE_X11=true
elif [[ -n "$WAYLAND_DISPLAY" || "$XDG_SESSION_TYPE" == wayland ]]; then
    if [[ "$IS_KDE" == true ]]; then
        USE_X11=true
        PLATFORM_FLAGS+=("--ozone-platform=x11")
    else
        PLATFORM_FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
    fi
else
    USE_X11=true
fi

# No GTK module pin, unlike the claude-desktop and obsidian launchers. Their newer
# Electron loads GTK with dlopen() and unloads it with dlclose(), which unmaps the
# XSETTINGS GTK modules under live callbacks. Electron 22 links libgtk-3 directly and
# never unloads it (the PKGBUILD checks this), and 60 KDE theme switches did not crash.

# Global Menu shortcut names (dbusmenu-shortcut-shim). Electron 22 already exports
# "Ctrl+,"; newer Electron exports "Ctrl+comma", which the shim rewrites, so a bump to
# a newer Electron needs no launcher change. The Global Menu only works under X11.
if [[ "$IS_KDE" == true && "$USE_X11" == true && "${ZALO_GLOBALMENU:-1}" != 0 && -f /usr/lib/dbusmenu-shortcut-shim/libdbusmenu-shortcut-shim.so ]]; then
    export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}/usr/lib/dbusmenu-shortcut-shim/libdbusmenu-shortcut-shim.so"
fi

exec /opt/zalo-for-linux/zalo "${PLATFORM_FLAGS[@]}" "${FLAGS[@]}" "$@"
