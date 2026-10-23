#!/usr/bin/env bash
# extract-fonts.sh: copy the Windows 11 fonts and license.rtf that the
# ttf-ms-win11 PKGBUILD needs into this directory.
#
# Usage: extract-fonts.sh <source>
#   <source> is one of:
#     - a Windows 11 ISO (Win11_*.iso from microsoft.com)
#     - an install.wim or install.esd taken from an ISO's sources/ folder
#     - a directory: a mounted Windows partition, its Windows folder, or a
#       folder of fonts copied from C:\Windows\Fonts (put license.rtf next to
#       them)
#
# Needs 7zip (for an ISO) and wimlib (for an ISO, .wim or .esd).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "$1 not found; install it with: sudo pacman -S --needed $2"; }

[ $# -eq 1 ] || { sed -n '5,13p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
SRC="$1"
[ -e "$SRC" ] || die "$SRC does not exist"

# The font list comes from the PKGBUILD's _ttf_ms_win11* arrays, so the two
# can never drift apart.
mapfile -t FONTS < <(
  set +u  # the PKGBUILD reads makepkg variables such as $BOLD
  # shellcheck disable=SC1091
  source "$HERE/PKGBUILD"
  printf '%s\n' "${_ttf_ms_win11[@]}" "${_ttf_ms_win11_japanese[@]}" \
    "${_ttf_ms_win11_korean[@]}" "${_ttf_ms_win11_sea[@]}" \
    "${_ttf_ms_win11_thai[@]}" "${_ttf_ms_win11_zh_cn[@]}" \
    "${_ttf_ms_win11_zh_tw[@]}" "${_ttf_ms_win11_other[@]}"
)
PKG_BUILD="$(grep -oP '^pkgver=\K.*' "$HERE/PKGBUILD")"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
OUT="$TMP/out"
mkdir -p "$OUT"

from_wim() {
  local wim="$1" build
  need wimextract wimlib
  # Every edition in the image ships the same fonts; image 1 is enough.
  build="$(wiminfo "$wim" 1 | awk -F': *' '
    $1=="Major Version"{ma=$2} $1=="Minor Version"{mi=$2}
    $1=="Build"{b=$2} $1=="Service Pack Build"{sp=$2}
    END{if (b) print ma"."mi"."b"."sp}')"
  [ -n "$build" ] && echo "Windows build in image: $build"
  echo "Extracting fonts from $(basename "$wim") (an .esd takes a few minutes)..."
  wimextract "$wim" 1 '/Windows/Fonts/*.ttf' '/Windows/Fonts/*.ttc' \
    --dest-dir "$OUT" --nullglob --no-acls --no-attributes
  # Each edition keeps its license under its own folder; take whichever is there.
  wimextract "$wim" 1 '/Windows/System32/Licenses/neutral/_Default/*/license.rtf' \
    --dest-dir "$TMP/lic" --preserve-dir-structure --nullglob --no-acls --no-attributes
  local lic
  lic="$(find "$TMP/lic" -name license.rtf -print -quit 2>/dev/null || true)"
  [ -n "$lic" ] && cp "$lic" "$OUT/license.rtf"
  BUILD="$build"
}

from_dir() {
  local dir="$1" fonts lic=""
  for fonts in "$dir/Windows/Fonts" "$dir/Fonts" "$dir"; do
    [ -f "$fonts/arial.ttf" ] && break
  done
  [ -f "$fonts/arial.ttf" ] || die "no arial.ttf found in $dir, $dir/Fonts or $dir/Windows/Fonts"
  cp -- "$fonts"/*.tt[fc] "$OUT"/ 2>/dev/null || true
  for lic in "$fonts/license.rtf" "$fonts"/../System32/Licenses/neutral/_Default/*/license.rtf; do
    [ -f "$lic" ] && { cp -- "$lic" "$OUT/license.rtf"; break; }
  done
}

case "$SRC" in
  *.iso|*.ISO)
    need 7z 7zip
    entry="$(7z l -ba "$SRC" 2>/dev/null | awk '{print $NF}' | grep -ixE 'sources/install\.(wim|esd)' | head -1 || true)"
    [ -n "$entry" ] || die "$SRC has no sources/install.wim or sources/install.esd"
    echo "Unpacking $entry from the ISO (about 5 GiB, needs that much free space in ${TMPDIR:-/tmp})..."
    7z e -bd -y -o"$TMP" "$SRC" "$entry" >/dev/null
    from_wim "$TMP/$(basename "$entry")"
    rm -f "$TMP/$(basename "$entry")"
    ;;
  *.wim|*.WIM|*.esd|*.ESD) from_wim "$SRC" ;;
  *) [ -d "$SRC" ] || die "$SRC is not an ISO, .wim, .esd or directory"; from_dir "$SRC" ;;
esac

missing=()
for f in "${FONTS[@]}" license.rtf; do
  if [ -f "$OUT/$f" ]; then
    install -m644 "$OUT/$f" "$HERE/$f"
  else
    missing+=("$f")
  fi
done

echo "Copied $(( ${#FONTS[@]} + 1 - ${#missing[@]} )) of $(( ${#FONTS[@]} + 1 )) files into $HERE"
if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing: ${missing[*]}" >&2
  echo "Your Windows build does not ship these; makepkg will stop until they are present." >&2
  exit 1
fi
if [ -n "${BUILD:-}" ] && [ "$BUILD" != "$PKG_BUILD" ]; then
  echo "Note: the PKGBUILD's checksums are for $PKG_BUILD, not $BUILD."
  echo "Build with:  makepkg -si --skipchecksums   (or run updpkgsums first)"
else
  echo "Now build and install with:  makepkg -si"
fi
