#!/bin/bash
# Prevent Electron/AppImage from creating unmanaged desktop files in ~/.local/share/applications
export DESKTOPINTEGRATION=0

# Enforce desktop file remoting / identity mapping
export CHROME_DESKTOP="${CHROME_DESKTOP:-beeper.desktop}"

# Clean any rogue user desktop files on launch just in case
rm -f "$HOME/.local/share/applications/Beeper.desktop" \
      "$HOME/.local/share/applications/beeper.desktop" \
      "$HOME/.local/share/applications/beepertexts.desktop" 2>/dev/null || true

# On Wayland, Electron lacks org_kde_kwin_appmenu Wayland protocol support.
# When KDE Plasma Global Menu is active, Electron attempts X11 D-Bus registration which fails,
# while erroneously dropping the in-window menu bar.
# Enforce in-window menu bar so the native Alt-key autohide menu functions reliably.
if [ -n "$WAYLAND_DISPLAY" ]; then
    export ELECTRON_FORCE_WINDOW_MENU_BAR="${ELECTRON_FORCE_WINDOW_MENU_BAR:-1}"
fi

# Enable Wayland Ozone platform auto-detection if on Wayland and not explicitly overridden
if [ -n "$WAYLAND_DISPLAY" ] && [ -z "$ELECTRON_OZONE_PLATFORM_HINT" ]; then
    export ELECTRON_OZONE_PLATFORM_HINT=auto
fi

exec /opt/beeper/AppRun --no-sandbox "$@"
