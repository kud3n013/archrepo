#!/bin/sh
# PdfCraft launcher (archrepo).
#
# The first time each user starts PdfCraft from this package, it turns on what upstream
# leaves off: Appearance set to Use system setting.
# PdfCraft then follows the desktop's light/dark setting live through the XDG portal.
# This happens once; after that PdfCraft's own settings decide.
# PDFCRAFT_ARCHREPO_DEFAULTS=0 skips it.
_state="${XDG_STATE_HOME:-$HOME/.local/state}/archrepo"
_marker="$_state/pdfcraft-defaults"
if [ "${PDFCRAFT_ARCHREPO_DEFAULTS:-1}" != 0 ] && [ ! -e "$_marker" ]; then
    _prefs="${XDG_CONFIG_HOME:-$HOME/.config}/pdfcraft/app.ron"
    # eframe's app.ron is RON, not JSON, so it is only written for a new profile.
    # PdfCraft moves an older app.ron from the legacy folder itself; leave that to it.
    _legacy="${XDG_DATA_HOME:-$HOME/.local/share}/pdfcraft/app.ron"
    if [ ! -e "$_prefs" ] && [ ! -e "$_legacy" ]; then
        (umask 077 && mkdir -p "${_prefs%/*}" &&
            printf '%s\n' '{"pdfcraft":"{\"theme\":\"System\"}"}' >"$_prefs")
    fi
    mkdir -p "$_state" && : >"$_marker"
fi

exec /usr/lib/pdfcraft/bin/pdfcraft "$@"
