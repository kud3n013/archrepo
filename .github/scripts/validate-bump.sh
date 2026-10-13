#!/usr/bin/env bash
# validate-bump.sh <current PKGBUILD> <bumped PKGBUILD>
#
# The bumped PKGBUILD comes from a build job that ran upstream code, and the
# publish job merges it to main. Accept it only if every changed line is a
# version/hash assignment or a checksum entry; anything else (new sources,
# functions, commands) needs a human review.
set -euo pipefail

[ $# -eq 2 ] || { echo "Usage: $0 <current PKGBUILD> <bumped PKGBUILD>" >&2; exit 2; }

VAR_RE='^(pkgver|pkgrel|_build|_commithash|_zadarkver)=["'\'']?[0-9A-Za-z._+]*["'\'']?$'
SUM_RE='^([a-z0-9]+sums(_[a-z0-9_]+)?=\()?([[:space:]]*["'\'']?([0-9a-fA-F]{32,128}|SKIP)["'\'']?)*[[:space:]]*\)?$'

bad=0
# Custom line formats print changed lines only, with no headers an attacker
# could imitate (a added line "++x" would otherwise look like a "+++" header)
while IFS= read -r line; do
  content="${line:1}"
  if [[ "$content" =~ $VAR_RE || "$content" =~ $SUM_RE ]]; then
    continue
  fi
  echo "Unexpected PKGBUILD change: ${line}" >&2
  bad=1
done < <(diff --old-line-format='-%L' --new-line-format='+%L' --unchanged-line-format='' "$1" "$2" || true)

exit "$bad"
