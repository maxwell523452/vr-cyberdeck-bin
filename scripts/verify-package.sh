#!/usr/bin/env bash
# Sanity checks on a built package.
#   scripts/verify-package.sh PACKAGE.pkg.tar.zst
# Needs: bsdtar.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

pkg="${1:?usage: verify-package.sh PACKAGE.pkg.tar.zst}"

listing="$(bsdtar -tf "$pkg")"
for path in \
  opt/vr-cyberdeck/vr-cyberdeck \
  opt/vr-cyberdeck/chrome-sandbox \
  opt/vr-cyberdeck/resources/app.asar \
  usr/bin/vr-cyberdeck \
  usr/share/applications/vr-cyberdeck.desktop \
  usr/share/icons/hicolor/512x512/apps/vr-cyberdeck.png \
  usr/share/licenses/vr-cyberdeck-bin/LICENSE \
  usr/lib/udev/rules.d/51-vr-cyberdeck-quest.rules; do
  grep -Fxq -- "$path" <<<"$listing" || die "package is missing ${path}"
done

if grep -q '^opt/VR CyberDeck' <<<"$listing"; then
  die "application directory was not renamed"
fi

desktop="$(bsdtar -xOf "$pkg" usr/share/applications/vr-cyberdeck.desktop)"
grep -q '^Exec=' <<<"$desktop" || die "desktop file has no Exec line"
if grep -q '/opt/VR CyberDeck' <<<"$desktop"; then
  die "desktop file still points to /opt/VR CyberDeck"
fi
grep -q '/opt/vr-cyberdeck/vr-cyberdeck' <<<"$desktop" \
  || die "desktop file does not point to /opt/vr-cyberdeck"

# No setuid/setgid files: the Electron sandbox runs on user namespaces.
if bsdtar -tvf "$pkg" | awk 'length($1) == 10 && (substr($1,4,1) ~ /[sS]/ || substr($1,7,1) ~ /[sS]/) { found = 1 } END { exit !found }'; then
  die "package contains setuid/setgid files"
fi

echo "package looks sane: $(basename "$pkg")"
