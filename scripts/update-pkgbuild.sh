#!/usr/bin/env bash
# Update PKGBUILD for an upstream version and recompute every checksum.
#
#   scripts/update-pkgbuild.sh            # keep version, just refresh checksums
#   scripts/update-pkgbuild.sh 2.1.0      # bump to 2.1.0 (pkgrel resets to 1)
#
# Needs: curl, python3, sha256sum.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

upstream="${UPSTREAM_REPO:-DeliciousMeatPop/VRCD}"
rules="51-vr-cyberdeck-quest.rules"

die() { echo "error: $*" >&2; exit 1; }

current_ver="$(sed -n 's/^pkgver=//p' PKGBUILD)"
current_rel="$(sed -n 's/^pkgrel=//p' PKGBUILD)"
ver="${1:-$current_ver}"

[[ $ver =~ ^[0-9]+(\.[0-9]+)*$ ]] || die "invalid version: ${ver}"
[[ -f $rules ]] || die "missing ${rules}"

if [[ $ver == "$current_ver" ]]; then rel="$current_rel"; else rel=1; fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fetch() { # url dest max-bytes
  curl --fail --silent --show-error --location \
    --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --retry 3 --retry-all-errors --max-filesize "$3" \
    --output "$2" "$1"
}

asset="vr-cyberdeck-${ver}-x86_64.AppImage"
raw="https://raw.githubusercontent.com/${upstream}/v${ver}"

echo ">> downloading upstream v${ver}"
fetch "https://github.com/${upstream}/releases/download/v${ver}/${asset}" "$tmp/appimage" 1073741824
fetch "${raw}/LICENSE" "$tmp/license" 1048576
fetch "${raw}/resources/icon.png" "$tmp/icon" 10485760

magic="$(head -c 4 "$tmp/appimage" | od -An -tx1 | tr -d ' \n')"
[[ $magic == 7f454c46 ]] || die "downloaded AppImage is not an ELF file"
grep -q 'GNU GENERAL PUBLIC LICENSE' "$tmp/license" \
  || die "upstream LICENSE is not GPL-3.0 any more - review license= in PKGBUILD"

# Order must match the source=() array in PKGBUILD.
sums=(
  "$(sha256sum "$tmp/appimage" | cut -d' ' -f1)"
  "$(sha256sum "$tmp/license" | cut -d' ' -f1)"
  "$(sha256sum "$tmp/icon" | cut -d' ' -f1)"
  "$(sha256sum "$rules" | cut -d' ' -f1)"
)

python3 - "$ver" "$rel" "${sums[@]}" <<'PY'
import re
import sys
from pathlib import Path

ver, rel, *sums = sys.argv[1:]
for s in sums:
    if not re.fullmatch(r"[0-9a-f]{64}", s):
        sys.exit(f"bad checksum: {s!r}")

path = Path("PKGBUILD")
text = path.read_text()


def replace_once(pattern, replacement, content, name):
    new, count = re.subn(pattern, lambda _m: replacement, content, count=1, flags=re.M)
    if count != 1:
        sys.exit(f"could not update {name}")
    return new


text = replace_once(r"^pkgver=[^\n]*$", f"pkgver={ver}", text, "pkgver")
text = replace_once(r"^pkgrel=[^\n]*$", f"pkgrel={rel}", text, "pkgrel")
body = "\n            ".join(f"'{s}'" for s in sums)
text = replace_once(r"^sha256sums=\([^)]*\)", f"sha256sums=({body})", text, "sha256sums")
path.write_text(text)
PY

echo ">> PKGBUILD updated: pkgver=${ver} pkgrel=${rel}"
printf '   %s\n' "${sums[@]}"
