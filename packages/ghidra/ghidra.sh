#!/bin/bash
# /usr/bin/ghidra: starts Ghidra's GUI (/opt/ghidra/ghidraRun) with the
# options from ~/.config/ghidra-flags.conf, or /etc/ghidra-flags.conf when the
# user has none, plus HiDPI and tiling window manager detection.

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/ghidra-flags.conf"
SYSTEM_FLAGS_FILE="/etc/ghidra-flags.conf"

CONFIG_FILE=""
if [[ -f "$USER_FLAGS_FILE" ]]; then
    CONFIG_FILE="$USER_FLAGS_FILE"
elif [[ -f "$SYSTEM_FLAGS_FILE" ]]; then
    CONFIG_FILE="$SYSTEM_FLAGS_FILE"
fi

# Java options: "-..." lines. Environment variables: NAME=value lines, which
# never override a variable already set in the environment.
JVM_OPTS=()
if [[ -n "$CONFIG_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        if [[ "$line" == -* ]]; then
            JVM_OPTS+=("$line")
        elif [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            _name="${BASH_REMATCH[1]}"
            _value="${BASH_REMATCH[2]}"
            [[ -z "${!_name+set}" ]] && export "${_name}=${_value}"
        fi
    done < "$CONFIG_FILE"
fi

# HiDPI. Upstream's launch.properties pins -Dsun.java2d.uiScale=1, so Java
# ignores the desktop's scale and Ghidra is tiny on a HiDPI screen. Unless a
# scale is set already, follow GDK_SCALE, else Xft.dpi (whole multiples of 96
# dpi only: Java's Swing scaling on Linux is unreliable at fractions).
_all_opts=" ${JVM_OPTS[*]} ${GHIDRA_JAVA_OPTIONS:-} ${GHIDRA_GUI_JAVA_OPTIONS:-} "
if [[ "$_all_opts" != *" -Dsun.java2d.uiScale="* ]]; then
    _scale=""
    if [[ "${GDK_SCALE:-}" =~ ^[1-9][0-9]*$ ]]; then
        _scale="$GDK_SCALE"
    elif [[ -n "${DISPLAY:-}" ]] && command -v xrdb &>/dev/null; then
        _dpi="$(xrdb -query 2>/dev/null | awk '$1 == "Xft.dpi:" { printf "%d", $2; exit }')"
        if [[ "$_dpi" =~ ^[0-9]+$ ]] && (( _dpi >= 192 )); then
            _scale=$(( _dpi / 96 ))
        fi
    fi
    [[ -n "$_scale" ]] && (( _scale > 1 )) && JVM_OPTS+=("-Dsun.java2d.uiScale=${_scale}")
fi

# Java draws blank or grey windows under window managers that don't reparent
# (wlroots-style Wayland compositors, whose Xwayland window manager doesn't
# either, and most X11 tiling WMs).
if [[ -z "${_JAVA_AWT_WM_NONREPARENTING+set}" ]]; then
    _desktop="${XDG_CURRENT_DESKTOP:-}:${XDG_SESSION_DESKTOP:-}:${DESKTOP_SESSION:-}"
    _desktop="${_desktop,,}"
    if [[ -n "${SWAYSOCK:-}${HYPRLAND_INSTANCE_SIGNATURE:-}${NIRI_SOCKET:-}" ]] ||
        [[ "$_desktop" =~ (^|[:/])(sway|hyprland|niri|river|wayfire|labwc|dwl|qtile|i3|bspwm|xmonad|dwm|herbstluftwm|leftwm|spectrwm)([:/]|$) ]]; then
        export _JAVA_AWT_WM_NONREPARENTING=1
    fi
fi

# ghidraRun passes GHIDRA_GUI_JAVA_OPTIONS to Java after launch.properties.
if (( ${#JVM_OPTS[@]} )); then
    export GHIDRA_GUI_JAVA_OPTIONS="${GHIDRA_GUI_JAVA_OPTIONS:+${GHIDRA_GUI_JAVA_OPTIONS} }${JVM_OPTS[*]}"
fi

exec /opt/ghidra/ghidraRun "$@"
