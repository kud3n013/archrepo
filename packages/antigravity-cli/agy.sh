#!/bin/sh
# pacman owns updates: stop agy from replacing itself (and failing, since
# /usr/lib is not writable) each time it starts. Only "true" disables it;
# AGY_CLI_DISABLE_AUTO_UPDATE=1 is ignored by upstream.
export AGY_CLI_DISABLE_AUTO_UPDATE="${AGY_CLI_DISABLE_AUTO_UPDATE:-true}"

exec /usr/lib/antigravity-cli/agy "$@"
