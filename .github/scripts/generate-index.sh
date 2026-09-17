#!/usr/bin/env bash
set -euo pipefail

# generate-index.sh: Dynamically creates index.html for gh-pages from repository PKGBUILDs.
# Usage: generate-index.sh <src_dir> <output_html>

SRC_DIR="${1:-.}"
OUTPUT_HTML="${2:-index.html}"
REPO_NAME="${GITHUB_REPOSITORY:-kud3n013/archrepo}"

mkdir -p "$(dirname "$OUTPUT_HTML")"

PKG_LIST=""
for d in "${SRC_DIR}/packages"/*/; do
  pkg_dir="${d%/}"
  pkg_name=$(basename "$pkg_dir")
  if [ -f "${pkg_dir}/PKGBUILD" ]; then
    name=$(grep -oP '^pkgname=\K.*' "${pkg_dir}/PKGBUILD" | tr -d '"'\' | head -1)
    desc=$(grep -oP '^pkgdesc=\K.*' "${pkg_dir}/PKGBUILD" | tr -d '"'\' | head -1)
    PKG_LIST+="${name}:::<li><code>${name}</code> - ${desc}</li>"$'\n'
  fi
done

SORTED_ITEMS=$(echo -n "$PKG_LIST" | sort -t: -k1,1 | cut -d: -f4- | sed 's/^/      /')

cat << EOF > "$OUTPUT_HTML"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>archrepo - Arch Linux Repository</title>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #24292f; }
    pre { background: #f6f8fa; padding: 16px; border-radius: 6px; overflow-x: auto; border: 1px solid #d0d7de; }
    code { font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace; }
    h1 { color: #0969da; }
    ul { line-height: 1.8; }
  </style>
</head>
<body>
  <h1>📦 archrepo</h1>
  <p>Automated Arch Linux package repository hosted on GitHub.</p>
  <h2>Installation</h2>
  <p>Add the repository to <code>/etc/pacman.conf</code>:</p>
  <pre><code>[archrepo]
SigLevel = Optional TrustAll
Server = https://github.com/${REPO_NAME}/releases/download/packages</code></pre>
  <p>Then synchronize package databases:</p>
  <pre><code>sudo pacman -Syy</code></pre>
  <h2>Available Packages</h2>
  <ul>
${SORTED_ITEMS}
  </ul>

</body>
</html>
EOF

echo "Generated ${OUTPUT_HTML} successfully."
