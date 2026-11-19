#!/bin/sh
# Launcher for Horizon, installed as /usr/bin/horizon-launcher.
# The real binary is /usr/lib/horizon-rust/horizon-launcher.

# pacman owns the binary: the launcher's own updater must not replace it.
export HORIZON_LAUNCHER_NO_SELF_UPDATE=1

# The menu entry the launcher writes under ~/.local/share/applications starts this
# wrapper, so it keeps working and keeps the variable above set.
export HORIZON_LAUNCHER_DESKTOP_EXEC="${HORIZON_LAUNCHER_DESKTOP_EXEC:-/usr/bin/horizon-launcher}"

exec /usr/lib/horizon-rust/horizon-launcher "$@"
