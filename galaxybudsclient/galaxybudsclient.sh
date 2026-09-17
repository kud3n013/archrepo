#!/usr/bin/env bash
# Launcher wrapper script for Galaxy Buds Manager (Avalonia .NET)
set -e

# Prevent rogue desktop files from runtime desktop integration
export DESKTOPINTEGRATION=0

# Clean any rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/galaxybudsclient.desktop" \
      "$HOME/.local/share/applications/GalaxyBudsClient.desktop" \
      "$HOME/.local/share/applications/Galaxy Buds Manager.desktop" 2>/dev/null || true

# Deploy EnsureTrayMenu user hook to ensure Open and Quit tray options are always available
USER_SCRIPTS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/GalaxyBudsClient/scripts"
mkdir -p "$USER_SCRIPTS_DIR"
if [[ -f "/opt/galaxybudsclient/scripts/EnsureTrayMenu.cs" ]]; then
    if ! cmp -s "/opt/galaxybudsclient/scripts/EnsureTrayMenu.cs" "$USER_SCRIPTS_DIR/EnsureTrayMenu.cs" 2>/dev/null; then
        cp -f "/opt/galaxybudsclient/scripts/EnsureTrayMenu.cs" "$USER_SCRIPTS_DIR/EnsureTrayMenu.cs" 2>/dev/null || true
    fi
fi

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/galaxybudsclient-flags.conf"
SYSTEM_FLAGS_FILE="/etc/galaxybudsclient-flags.conf"

FLAGS=()

# 1. Load user configuration (~/.config/galaxybudsclient-flags.conf) or system fallback
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

# 2. Universal Wayland / HiDPI Auto-Scaling Detection for Avalonia
# Avalonia uses X11/XWayland by default. Under compositors like Hyprland, Sway, or KDE,
# XWayland windows do not automatically receive fractional scaling or Xft.dpi from the compositor,
# causing unscaled (tiny/microscopic) or blurry windows.
# We auto-detect the active monitor scale factor if not explicitly set by the user.
if [[ -z "$AVALONIA_GLOBAL_SCALE_FACTOR" && -z "$AVALONIA_SCREEN_SCALE_FACTORS" ]]; then
    # Hyprland: query monitor scales
    if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]] && command -v hyprctl &>/dev/null; then
        if command -v jq &>/dev/null; then
            HYPR_DATA=$(hyprctl -j monitors 2>/dev/null || true)
            if [[ -n "$HYPR_DATA" && "$HYPR_DATA" != "null" ]]; then
                UNIQUE_SCALES=$(echo "$HYPR_DATA" | jq -r '[.[].scale] | unique | .[]' 2>/dev/null || true)
                COUNT=$(echo "$UNIQUE_SCALES" | grep -c . || true)
                if [[ "$COUNT" -eq 1 ]]; then
                    SCALE=$(echo "$UNIQUE_SCALES" | head -n 1)
                    if [[ -n "$SCALE" && "$SCALE" != "1" && "$SCALE" != "1.0" && "$SCALE" != "0" ]]; then
                        export AVALONIA_GLOBAL_SCALE_FACTOR="$SCALE"
                    fi
                elif [[ "$COUNT" -gt 1 ]]; then
                    FACTORS=$(echo "$HYPR_DATA" | jq -r '[.[] | "\(.name)=\(.scale)"] | join(";")' 2>/dev/null || true)
                    if [[ -n "$FACTORS" ]]; then
                        export AVALONIA_SCREEN_SCALE_FACTORS="$FACTORS"
                    fi
                fi
            fi
        else
            # Awk fallback for Hyprland if jq is not installed
            FACTORS=$(hyprctl monitors 2>/dev/null | awk '/^Monitor / {mon=$2} /^[[:space:]]*scale:[[:space:]]*/ {print mon "=" $2}' | paste -sd ';' -)
            if [[ -n "$FACTORS" ]]; then
                SCALES=$(echo "$FACTORS" | tr ';' '\n' | cut -d= -f2 | sort -u)
                if [[ $(echo "$SCALES" | grep -c .) -eq 1 ]]; then
                    SCALE=$(echo "$SCALES" | head -n 1)
                    if [[ -n "$SCALE" && "$SCALE" != "1" && "$SCALE" != "1.0" && "$SCALE" != "0" ]]; then
                        export AVALONIA_GLOBAL_SCALE_FACTOR="$SCALE"
                    fi
                else
                    export AVALONIA_SCREEN_SCALE_FACTORS="$FACTORS"
                fi
            fi
        fi
    # Sway: query outputs
    elif [[ -n "$SWAYSOCK" ]] && command -v swaymsg &>/dev/null; then
        if command -v jq &>/dev/null; then
            SWAY_DATA=$(swaymsg -t get_outputs 2>/dev/null || true)
            if [[ -n "$SWAY_DATA" && "$SWAY_DATA" != "null" ]]; then
                UNIQUE_SCALES=$(echo "$SWAY_DATA" | jq -r '[.[].scale] | unique | .[]' 2>/dev/null || true)
                COUNT=$(echo "$UNIQUE_SCALES" | grep -c . || true)
                if [[ "$COUNT" -eq 1 ]]; then
                    SCALE=$(echo "$UNIQUE_SCALES" | head -n 1)
                    if [[ -n "$SCALE" && "$SCALE" != "1" && "$SCALE" != "1.0" && "$SCALE" != "0" ]]; then
                        export AVALONIA_GLOBAL_SCALE_FACTOR="$SCALE"
                    fi
                elif [[ "$COUNT" -gt 1 ]]; then
                    FACTORS=$(echo "$SWAY_DATA" | jq -r '[.[] | "\(.name)=\(.scale)"] | join(";")' 2>/dev/null || true)
                    if [[ -n "$FACTORS" ]]; then
                        export AVALONIA_SCREEN_SCALE_FACTORS="$FACTORS"
                    fi
                fi
            fi
        fi
    # KDE Plasma Wayland
    elif [[ "${XDG_CURRENT_DESKTOP:-}" =~ (KDE|plasma) ]] && command -v kreadconfig6 &>/dev/null; then
        KDE_SCALE=$(kreadconfig6 --file kdeglobals --group KScreen --key ScaleFactor 2>/dev/null || true)
        if [[ -n "$KDE_SCALE" && "$KDE_SCALE" != "1" && "$KDE_SCALE" != "1.0" && "$KDE_SCALE" != "0" ]]; then
            export AVALONIA_GLOBAL_SCALE_FACTOR="$KDE_SCALE"
        fi
    elif [[ "${XDG_CURRENT_DESKTOP:-}" =~ (KDE|plasma) ]] && command -v kreadconfig5 &>/dev/null; then
        KDE_SCALE=$(kreadconfig5 --file kdeglobals --group KScreen --key ScaleFactor 2>/dev/null || true)
        if [[ -n "$KDE_SCALE" && "$KDE_SCALE" != "1" && "$KDE_SCALE" != "1.0" && "$KDE_SCALE" != "0" ]]; then
            export AVALONIA_GLOBAL_SCALE_FACTOR="$KDE_SCALE"
        fi
    # Toolkit scale factor fallbacks
    elif [[ -n "${GDK_SCALE:-}" && "${GDK_SCALE}" != "1" && "${GDK_SCALE}" != "0" ]]; then
        export AVALONIA_GLOBAL_SCALE_FACTOR="$GDK_SCALE"
    elif [[ -n "${QT_SCALE_FACTOR:-}" && "${QT_SCALE_FACTOR}" != "1" && "${QT_SCALE_FACTOR}" != "0" ]]; then
        export AVALONIA_GLOBAL_SCALE_FACTOR="$QT_SCALE_FACTOR"
    # Xft.dpi from xrdb
    elif command -v xrdb &>/dev/null; then
        DPI=$(xrdb -query 2>/dev/null | grep -i 'Xft.dpi:' | awk '{print $2}' | head -n 1)
        if [[ -n "$DPI" && "$DPI" -gt 96 ]]; then
            SCALE=$(awk -v dpi="$DPI" 'BEGIN { printf "%.2f", dpi / 96 }')
            export AVALONIA_GLOBAL_SCALE_FACTOR="$SCALE"
        fi
    fi
fi

exec /opt/galaxybudsclient/GalaxyBudsClient "${FLAGS[@]}" "$@"
