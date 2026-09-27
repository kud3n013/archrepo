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

# Wayland routing
HAS_OZONE=false
for arg in "$@" "${FLAGS[@]}"; do
    [[ "$arg" == --ozone-platform* ]] && HAS_OZONE=true && break
done

DEFAULT_PLATFORM_FLAGS=()
if [[ "$HAS_OZONE" == false && -n "$WAYLAND_DISPLAY" ]]; then
    DEFAULT_PLATFORM_FLAGS+=("--ozone-platform-hint=auto" "--enable-wayland-ime")
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
