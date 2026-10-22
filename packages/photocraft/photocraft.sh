#!/bin/sh
# PhotoCraft launcher (archrepo).
#
# The first time each user starts PhotoCraft from this package, it turns on what
# upstream leaves off: Preferences › Interface › System Title Bar on, and Appearance set
# to Auto.
# The window then gets the desktop's own title bar (KDE and other compositors with
# server-side decorations) and follows its light/dark setting live through the XDG
# portal. This happens once; after that PhotoCraft's own settings decide.
# PHOTOCRAFT_ARCHREPO_DEFAULTS=0 skips it.
_state="${XDG_STATE_HOME:-$HOME/.local/state}/archrepo"
_marker="$_state/photocraft-defaults"
if [ "${PHOTOCRAFT_ARCHREPO_DEFAULTS:-1}" != 0 ] && [ ! -e "$_marker" ]; then
    _prefs="${XDG_CONFIG_HOME:-$HOME/.config}/photocraft/preferences.json"
    _set='.interface.systemTitleBar = true | .interface.appearanceMode = "auto"'
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

exec /usr/lib/photocraft/bin/photocraft "$@"
