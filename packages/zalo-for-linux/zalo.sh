#!/bin/bash
# Launcher for Zalo, installed as /usr/bin/zalo.
# The real binary is /opt/zalo-for-linux/zalo (Electron 22).

# Stop AppImage-style launchers from writing per-user desktop files.
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

HAS_OZONE=false
for arg in "${FLAGS[@]}" "$@"; do
    if [[ "$arg" == --ozone-platform* ]]; then
        HAS_OZONE=true
        break
    fi
done

IS_KDE=false
if [[ "$XDG_CURRENT_DESKTOP" =~ [Kk][Dd][Ee]|[Pp]lasma ]] || [[ "$KDE_FULL_SESSION" == "true" ]]; then
    IS_KDE=true
fi

# On KDE Plasma, run under XWayland. Electron 22 draws no window decorations on
# native Wayland, and its Global Menu export only works on X11, so XWayland is the
# only way to get both the KWin title bar and the Plasma Global Menu. Elsewhere,
# default to native Wayland, where upstream adds its own window buttons.
# A --ozone-platform flag from the user always wins.
PLATFORM_FLAGS=()
if [[ "$HAS_OZONE" == false && ( -n "$WAYLAND_DISPLAY" || "$XDG_SESSION_TYPE" == wayland ) ]]; then
    if [[ "$IS_KDE" == true ]]; then
        PLATFORM_FLAGS+=("--ozone-platform=x11")
    else
        PLATFORM_FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
    fi
fi

# Under X11 or XWayland, GTK loads the modules set in XSETTINGS (appmenu-gtk-module,
# colorreload-gtk-module, ...). Electron unloads GTK with dlclose(), which unmaps
# those modules while their GIO monitors and D-Bus callbacks stay registered, and
# the next GIO callback (a theme change, for example) crashes with SIGSEGV
# (SEGV_ACCERR). Pin the GTK3 modules into memory so dlclose() cannot unmap them.
for _mod in /usr/lib/gtk-3.0/modules/*.so; do
    if [[ -f "$_mod" ]]; then
        export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$_mod"
    fi
done

# Global Menu shortcut tips: Plasma can't parse key names such as "comma", so
# Ctrl+, (Preferences) would show no shortcut. The shim rewrites them.
_shim=/usr/lib/dbusmenu-shortcut-shim/libdbusmenu-shortcut-shim.so
if [[ "$IS_KDE" == true && -f "$_shim" ]]; then
    export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$_shim"
fi

exec /opt/zalo-for-linux/zalo "${PLATFORM_FLAGS[@]}" "${FLAGS[@]}" "$@"
