#!/bin/bash
set -eo pipefail

# Disable AppImage runtime desktop integration if any
export DESKTOPINTEGRATION=0

# Clean any rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/sine.desktop" \
      "$HOME/.local/share/applications/Sine.desktop" \
      "$HOME/.local/share/applications/sine-installer.desktop" \
      "$HOME/.local/share/applications/Sine Installer.desktop" 2>/dev/null || true

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/sine-flags.conf"
SYSTEM_FLAGS_FILE="/etc/sine-flags.conf"

FLAGS=()

# Prefer user configuration in ~/.config/sine-flags.conf, fallback to system config /etc/sine-flags.conf
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

# ==============================================================================
# Universal HiDPI & Wayland Scaling Detection for GLFW / ImGui
# ==============================================================================
# GLFW on Linux reads Xft.dpi from the X server resource manager string
# (XResourceManagerString) to determine window content scale. Under Wayland
# (Hyprland, Sway, KDE, GNOME), Xwayland often lacks an Xft.dpi entry, defaulting
# to 96 DPI (1.0x scale) even on high-DPI (2K/4K) displays.
# We dynamically detect the active display's scale factor across all desktop
# environments and compositors, setting Xft.dpi for the Sine process session.
# ==============================================================================
detect_scale() {
    local scale=""

    # 1. Explicit user override
    if [[ -n "${SINE_SCALE:-}" ]]; then
        echo "$SINE_SCALE"
        return
    fi
    if [[ -n "${SINE_DPI:-}" ]]; then
        awk -v d="$SINE_DPI" 'BEGIN { printf "%.2f", d / 96 }'
        return
    fi
    if [[ -n "${GDK_SCALE:-}" ]]; then
        echo "$GDK_SCALE"
        return
    fi
    if [[ -n "${QT_SCALE_FACTOR:-}" ]]; then
        echo "$QT_SCALE_FACTOR"
        return
    fi

    # 2. Wayland compositors
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        # Hyprland
        if command -v hyprctl &>/dev/null && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            scale=$(hyprctl monitors 2>/dev/null | grep -oP 'scale:\s*\K[0-9.]+' | head -1 || true)
            if [[ -n "$scale" && "$scale" != "0" ]]; then
                echo "$scale"
                return
            fi
        fi

        # Sway / wlroots
        if command -v swaymsg &>/dev/null && [[ -n "${SWAYSOCK:-}" ]]; then
            scale=$(swaymsg -t get_outputs 2>/dev/null | grep -oP '"scale":\s*\K[0-9.]+' | head -1 || true)
            if [[ -n "$scale" && "$scale" != "0" ]]; then
                echo "$scale"
                return
            fi
        fi

        # GNOME Wayland
        if command -v gsettings &>/dev/null && [[ "${XDG_CURRENT_DESKTOP:-}" =~ [Gg][Nn][Oo][Mm][Ee] ]]; then
            scale=$(gsettings get org.gnome.desktop.interface scaling-factor 2>/dev/null | grep -oP '[0-9]+' | head -1 || true)
            if [[ -n "$scale" && "$scale" != "0" ]]; then
                echo "$scale"
                return
            fi
        fi

        # KDE Plasma Wayland
        if command -v kreadconfig6 &>/dev/null; then
            scale=$(kreadconfig6 --file kdeglobals --group KScreen --key ScaleFactor 2>/dev/null || true)
            if [[ -n "$scale" && "$scale" != "0" ]]; then
                echo "$scale"
                return
            fi
        elif command -v kreadconfig5 &>/dev/null; then
            scale=$(kreadconfig5 --file kdeglobals --group KScreen --key ScaleFactor 2>/dev/null || true)
            if [[ -n "$scale" && "$scale" != "0" ]]; then
                echo "$scale"
                return
            fi
        fi

        # Generic wlr-randr
        if command -v wlr-randr &>/dev/null; then
            scale=$(wlr-randr 2>/dev/null | grep -oP 'Scale:\s*\K[0-9.]+' | head -1 || true)
            if [[ -n "$scale" && "$scale" != "0" ]]; then
                echo "$scale"
                return
            fi
        fi
    fi

    # 3. Existing Xft.dpi in xrdb
    if command -v xrdb &>/dev/null; then
        local xft_dpi
        xft_dpi=$(xrdb -query 2>/dev/null | grep -i '^Xft.dpi:' | awk '{print $2}' | head -1 || true)
        if [[ -n "$xft_dpi" && "$xft_dpi" != "0" ]]; then
            awk -v d="$xft_dpi" 'BEGIN { printf "%.2f", d / 96 }'
            return
        fi
    fi

    # 4. X11 / Xwayland physical display dimension heuristic via xrandr
    if command -v xrandr &>/dev/null; then
        local line
        line=$(xrandr --current 2>/dev/null | grep -E ' connected.* [0-9]+mm x [0-9]+mm' | head -1 || true)
        if [[ -n "$line" ]]; then
            local px mm
            px=$(echo "$line" | grep -oP '\b[0-9]+(?=x[0-9]+\+)' | head -1 || true)
            mm=$(echo "$line" | grep -oP '\b[0-9]+(?=mm x)' | head -1 || true)
            if [[ -n "$px" && -n "$mm" && "$mm" -gt 0 ]]; then
                local calc_dpi
                calc_dpi=$(( px * 254 / (mm * 10) ))
                awk -v d="$calc_dpi" 'BEGIN { printf "%.2f", d / 96 }'
                return
            fi
        fi
    fi

    echo "1.0"
}

TARGET_SCALE=$(detect_scale)
TARGET_DPI=$(awk -v s="$TARGET_SCALE" 'BEGIN { printf "%.0f", s * 96 }')

ORIG_XRESOURCES=""
if command -v xrdb &>/dev/null; then
    ORIG_XRESOURCES=$(xrdb -query 2>/dev/null || true)
fi

cleanup_xrdb() {
    if command -v xrdb &>/dev/null; then
        if [[ -n "$ORIG_XRESOURCES" ]]; then
            echo "$ORIG_XRESOURCES" | xrdb -load 2>/dev/null || true
        else
            xrdb -remove 2>/dev/null || true
        fi
    fi
}
trap cleanup_xrdb EXIT INT TERM

# Apply target DPI to X server resources so GLFW picks up the scale
if command -v xrdb &>/dev/null && [[ -n "$TARGET_DPI" && "$TARGET_DPI" -gt 0 ]]; then
    echo "Xft.dpi: $TARGET_DPI" | xrdb -merge 2>/dev/null || true
fi

/opt/sine/sine "${FLAGS[@]}" "$@" &
APP_PID=$!
wait "$APP_PID"
APP_EXIT_CODE=$?
exit "$APP_EXIT_CODE"
