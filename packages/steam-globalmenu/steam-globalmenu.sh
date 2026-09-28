#!/usr/bin/env bash
set -euo pipefail

# Launcher wrapper for Steam KDE Plasma Global Menu Bridge
exec /usr/lib/steam-globalmenu/steam-globalmenu.py "$@"
