#!/bin/sh
# LightCraft launcher (archrepo).
#
# The first time each user starts LightCraft from this package, it turns on what
# upstream leaves off: Settings › Interface › Appearance set to Auto.
# LightCraft then follows the desktop's light/dark setting live through the XDG portal.
# This happens once; after that LightCraft's own settings decide.
# LIGHTCRAFT_ARCHREPO_DEFAULTS=0 skips it.
_state="${XDG_STATE_HOME:-$HOME/.local/state}/archrepo"
_marker="$_state/lightcraft-defaults"
if [ "${LIGHTCRAFT_ARCHREPO_DEFAULTS:-1}" != 0 ] && [ ! -e "$_marker" ]; then
    _prefs="${LIGHTCRAFT_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/lightcraft}/ui.json"
    _set='.settings.appearanceMode = "auto"'
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

exec /usr/lib/lightcraft/bin/lightcraft "$@"
