#!/bin/bash
# Prevent AppImage from writing unmanaged desktop files to ~/.local/share/applications
export DESKTOPINTEGRATION=0

# Default to Wayland Ozone platform if not explicitly set
if [ -z "$OZONE_PLATFORM" ]; then
    export OZONE_PLATFORM=wayland
fi

exec /opt/zalo-for-linux/zalo.AppImage "$@"
