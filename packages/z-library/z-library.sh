#!/bin/bash
# Launcher for the Z-Library desktop app, installed as /usr/bin/z-library.
# The real binary is /opt/z-library/Z-Library.

# Stop Electron from writing per-user desktop files. The package ships its own.
export DESKTOPINTEGRATION=0

# Electron uses this to match the window to its desktop entry on Wayland.
export CHROME_DESKTOP="${CHROME_DESKTOP:-z-library.desktop}"

# Flags: the user file wins over the system file, the same as the other wrappers.
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/z-library-flags.conf"
SYSTEM_FLAGS_FILE="/etc/z-library-flags.conf"

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

# KDE Plasma Global Menu. On native Wayland, Electron exports the menu over D-Bus
# but nothing binds it to the window, so Plasma shows no menu. Under XWayland the
# window has an X id that the Plasma registrar can match, so on KDE the app runs
# under XWayland. Set Z_LIBRARY_GLOBALMENU=0 to keep native Wayland and lose the
# Global Menu. Other Wayland desktops get native Wayland.
IS_KDE=false
if [[ "$XDG_CURRENT_DESKTOP" =~ [Kk][Dd][Ee]|[Pp]lasma ]] || [[ "$KDE_FULL_SESSION" == "true" ]]; then
    IS_KDE=true
fi

USE_GLOBALMENU_X11=false
PLATFORM_FLAGS=()
if [[ "$HAS_OZONE" == false && ( -n "$WAYLAND_DISPLAY" || "$XDG_SESSION_TYPE" == wayland ) ]]; then
    if [[ "$IS_KDE" == true && "${Z_LIBRARY_GLOBALMENU:-1}" != 0 ]]; then
        USE_GLOBALMENU_X11=true
        PLATFORM_FLAGS+=("--ozone-platform=x11")
    else
        PLATFORM_FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
    fi
elif [[ "$IS_KDE" == true && -n "$DISPLAY" ]]; then
    # Plain X11 Plasma session.
    USE_GLOBALMENU_X11=true
fi

if [[ "$USE_GLOBALMENU_X11" == true ]]; then
    # Under X11, GTK loads the modules set in XSETTINGS (appmenu-gtk-module,
    # colorreload-gtk-module, ...). Electron unloads GTK with dlclose(), which
    # unmaps those modules while their GIO monitors and D-Bus callbacks stay
    # registered, and the next GIO callback crashes (SIGSEGV, SEGV_ACCERR). Pin the
    # GTK3 modules into memory so dlclose() cannot unmap them.
    for _mod in /usr/lib/gtk-3.0/modules/*.so; do
        if [[ -f "$_mod" ]]; then
            export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$_mod"
        fi
    done
fi

exec /opt/z-library/Z-Library "${PLATFORM_FLAGS[@]}" "${FLAGS[@]}" "$@"
