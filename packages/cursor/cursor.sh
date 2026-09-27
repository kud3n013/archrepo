#!/bin/bash
export DESKTOPINTEGRATION=0

# Clean rogue user desktop files
rm -f "$HOME/.local/share/applications/cursor.desktop" \
      "$HOME/.local/share/applications/cursor-url-handler.desktop" 2>/dev/null || true

# Load flags configuration
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
FLAGS=()
for conf in "/etc/cursor-flags.conf" "$XDG_CONFIG_HOME/cursor-flags.conf"; do
    if [[ -f "$conf" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            FLAGS+=("$line")
        done < "$conf"
    fi
done

# Detect desktop environment
IS_KDE=false
if [[ "$XDG_CURRENT_DESKTOP" =~ [Kk][Dd][Ee]|plasma|Plasma ]] || [[ "$KDE_FULL_SESSION" == "true" ]]; then
    IS_KDE=true
fi

# Wayland routing
HAS_OZONE=false
for arg in "$@" "${FLAGS[@]}"; do
    [[ "$arg" == --ozone-platform* ]] && HAS_OZONE=true && break
done

DEFAULT_PLATFORM_FLAGS=()
if [[ "$HAS_OZONE" == false && -n "$WAYLAND_DISPLAY" ]]; then
    if [[ "$IS_KDE" == true ]]; then
        # On KDE Plasma Wayland, route via XWayland to enable KWin DBus Global Menu export
        DEFAULT_PLATFORM_FLAGS+=("--ozone-platform=x11")
        export CURSOR_EXPORT_GLOBAL_MENU="1"
    else
        # On other Wayland compositors (Hyprland, Sway, GNOME), use native Wayland
        DEFAULT_PLATFORM_FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
        export ELECTRON_FORCE_WINDOW_MENU_BAR="${ELECTRON_FORCE_WINDOW_MENU_BAR:-1}"
    fi
elif [[ "$IS_KDE" == true ]]; then
    # Under native X11 on KDE Plasma
    export CURSOR_EXPORT_GLOBAL_MENU="1"
fi

# Under X11/XWayland on KDE Plasma, pin GTK3 modules to prevent dlclose() unmapping crashes (SIGSEGV SEGV_ACCERR)
if [[ "$IS_KDE" == true ]]; then
    for _mod in /usr/lib/gtk-3.0/modules/*.so; do
        [[ -f "$_mod" ]] && export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$_mod"
    done
    if [[ -f "/opt/cursor/libcursor-globalmenu.so" ]]; then
        export LD_PRELOAD="/opt/cursor/libcursor-globalmenu.so${LD_PRELOAD:+:${LD_PRELOAD}}"
    fi
fi

# Detect CLI-only subcommands/flags that should avoid injecting Ozone platform flags
IS_CLI_ONLY=false
if [[ "$1" == "agent" ]]; then
    IS_CLI_ONLY=true
else
    for arg in "$@"; do
        case "$arg" in
            -h|--help|-v|--version|--status|--list-extensions|--install-extension*|--uninstall-extension*)
                IS_CLI_ONLY=true
                break
                ;;
        esac
    done
fi

if [[ "$IS_CLI_ONLY" == true ]]; then
    exec /opt/cursor/bin/cursor "$@"
else
    exec /opt/cursor/bin/cursor "${DEFAULT_PLATFORM_FLAGS[@]}" "${FLAGS[@]}" "$@"
fi
