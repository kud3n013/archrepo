#!/bin/sh
# CADCraft launcher (archrepo).
#
# The first time each user starts CADCraft from this package, it turns on what upstream
# leaves off: Theme set to System.
# CADCraft then follows the desktop's light/dark setting live through the XDG portal.
# This happens once; after that CADCraft's own settings decide.
# CADCRAFT_ARCHREPO_DEFAULTS=0 skips it.
_state="${XDG_STATE_HOME:-$HOME/.local/state}/archrepo"
_marker="$_state/cadcraft-defaults"
if [ "${CADCRAFT_ARCHREPO_DEFAULTS:-1}" != 0 ] && [ ! -e "$_marker" ]; then
    _prefs="${XDG_DATA_HOME:-$HOME/.local/share}/ai.storyteller.cadcraft/app.ron"
    # eframe's app.ron is RON, not JSON, so it is only written for a new profile.
    if [ ! -e "$_prefs" ]; then
        (umask 077 && mkdir -p "${_prefs%/*}" &&
            printf '%s\n' '{"cadcraft.prefs":"{\"theme\":\"system\"}"}' >"$_prefs")
    fi
    mkdir -p "$_state" && : >"$_marker"
fi

exec /usr/lib/cadcraft/bin/cadcraft "$@"
