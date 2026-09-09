#!/bin/bash
# Prevent Electron/AppImage from creating unmanaged desktop files in ~/.local/share/applications
export DESKTOPINTEGRATION=0

# Enable Wayland Ozone platform auto-detection if on Wayland and not explicitly overridden
if [ -n "$WAYLAND_DISPLAY" ] && [ -z "$ELECTRON_OZONE_PLATFORM_HINT" ]; then
    export ELECTRON_OZONE_PLATFORM_HINT=auto
fi

exec /opt/beeper/AppRun --no-sandbox "$@"
