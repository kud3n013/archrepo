#!/bin/sh
# FilmCraft launcher (archrepo).
#
# The first time each user starts FilmCraft from this package, it turns on what upstream
# leaves off: Settings › Appearance › Appearance Mode set to Auto.
# FilmCraft then follows the desktop's light/dark setting live through the XDG portal.
# This happens once; after that FilmCraft's own settings decide.
# FILMCRAFT_ARCHREPO_DEFAULTS=0 skips it.
_state="${XDG_STATE_HOME:-$HOME/.local/state}/archrepo"
_marker="$_state/filmcraft-defaults"
if [ "${FILMCRAFT_ARCHREPO_DEFAULTS:-1}" != 0 ] && [ ! -e "$_marker" ]; then
    _prefs="${FILMCRAFT_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/filmcraft}/preferences.json"
    _set='.appearance.appearanceMode = "auto"'
    if [ -s "$_prefs" ]; then
        # Merge into the saved settings; a file jq can't read is left alone.
        _tmp="$_prefs.archrepo.$$"
        if jq "$_set" "$_prefs" >"$_tmp" 2>/dev/null; then
            mv -f "$_tmp" "$_prefs"
        else
            rm -f "$_tmp"
        fi
    else
        # The app fills in every other setting from its defaults.
        mkdir -p "${_prefs%/*}" && jq -n "$_set" >"$_prefs"
    fi
    mkdir -p "$_state" && : >"$_marker"
fi

exec /usr/lib/filmcraft/bin/filmcraft "$@"
