#!/bin/sh
# EffectCraft launcher (archrepo).
#
# The first time each user starts EffectCraft from this package, it turns on what
# upstream leaves off: Settings › Appearance › Appearance Mode set to Sync with System.
# EffectCraft then follows the desktop's light/dark setting live through the XDG portal.
# This happens once; after that EffectCraft's own settings decide.
# EFFECTCRAFT_ARCHREPO_DEFAULTS=0 skips it.
_state="${XDG_STATE_HOME:-$HOME/.local/state}/archrepo"
_marker="$_state/effectcraft-defaults"
if [ "${EFFECTCRAFT_ARCHREPO_DEFAULTS:-1}" != 0 ] && [ ! -e "$_marker" ]; then
    _prefs="${EFFECTCRAFT_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/effectcraft}/prefs.json"
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

exec /usr/lib/effectcraft/bin/effectcraft "$@"
