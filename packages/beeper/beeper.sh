#!/bin/bash
# Prevent Electron/AppImage from creating unmanaged desktop files in ~/.local/share/applications
export DESKTOPINTEGRATION=0

# Clean any rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/Beeper.desktop" \
      "$HOME/.local/share/applications/beepertexts.desktop" 2>/dev/null || true

# Enable Wayland Ozone platform auto-detection if on Wayland and not explicitly overridden
if [ -n "$WAYLAND_DISPLAY" ] && [ -z "$ELECTRON_OZONE_PLATFORM_HINT" ]; then
    export ELECTRON_OZONE_PLATFORM_HINT=auto
fi

exec /opt/beeper/AppRun --no-sandbox "$@"
