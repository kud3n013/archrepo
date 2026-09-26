#!/usr/bin/env bash
set -e

# Disable rogue desktop integration hooks
export DESKTOPINTEGRATION=0

# Clean rogue user desktop files
rm -f "$HOME/.local/share/applications/zed.desktop" 2>/dev/null || true
rm -f "$HOME/.local/share/applications/dev.zed.Zed.desktop" 2>/dev/null || true

# Load user and system flags configuration
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SYSTEM_FLAGS_FILE="/etc/zed-flags.conf"
USER_FLAGS_FILE="$XDG_CONFIG_HOME/zed-flags.conf"

FLAGS=()
for conf in "$SYSTEM_FLAGS_FILE" "$USER_FLAGS_FILE"; do
    if [[ -f "$conf" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Trim whitespace
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            [[ -z "$line" || "$line" =~ ^# ]] && continue

            # Export KEY=VALUE environment variables directly
            if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
                export "$line"
            else
                FLAGS+=("$line")
            fi
        done < "$conf"
    fi
done

# Zed is a native Rust GPUI application rendering directly via Vulkan.
# On Wayland (KDE Plasma 6, GNOME, Hyprland), it connects natively without XWayland routing.
# Execute the Zed CLI binary which handles IPC connection to any existing instance or launches the editor.
exec /usr/lib/zed/zed-cli "${FLAGS[@]}" "$@"
