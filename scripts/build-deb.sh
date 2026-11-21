#!/usr/bin/env bash
# Build a .deb from the already built (and checksum-verified) Arch package, so
# both formats ship exactly the same files.
#
#   scripts/build-deb.sh PACKAGE.pkg.tar.zst OUTDIR
#
# Needs: dpkg-deb, tar (with zstd installed to read the Arch package).
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

pkg="${1:?usage: build-deb.sh PACKAGE.pkg.tar.zst OUTDIR}"
outdir="${2:?usage: build-deb.sh PACKAGE.pkg.tar.zst OUTDIR}"

base="$(basename "$pkg")"
re='^vr-cyberdeck-bin-([0-9]+(\.[0-9]+)*)-([0-9]+)-x86_64\.pkg\.tar\.zst$'
[[ $base =~ $re ]] || die "unexpected package name: ${base}"
debver="${BASH_REMATCH[1]}-${BASH_REMATCH[3]}"
deb="vr-cyberdeck-bin_${debver}_amd64.deb"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
root="$work/root"
mkdir -p "$root"

tar -xpf "$pkg" -C "$root"
rm -f "$root/.PKGINFO" "$root/.BUILDINFO" "$root/.MTREE" "$root/.INSTALL"

# Debian keeps licenses under /usr/share/doc/<pkg>/copyright
lic="$root/usr/share/licenses/vr-cyberdeck-bin/LICENSE"
[[ -f $lic ]] || die "license file missing in package"
install -Dm644 "$lic" "$root/usr/share/doc/vr-cyberdeck-bin/copyright"
rm -rf "$root/usr/share/licenses"

for path in \
  opt/vr-cyberdeck/vr-cyberdeck.AppImage \
  usr/bin/vr-cyberdeck \
  usr/share/applications/vr-cyberdeck.desktop \
  usr/share/pixmaps/vr-cyberdeck.png \
  usr/lib/udev/rules.d/51-vr-cyberdeck-quest.rules; do
  [[ -f $root/$path ]] || die "missing ${path} in package"
done

size="$(du -sk "$root" | cut -f1)"
install -d -m 0755 "$root/DEBIAN"

# Alternatives ("a | b") cover the t64 library renames in newer Debian/Ubuntu.
cat > "$root/DEBIAN/control" <<EOF
Package: vr-cyberdeck-bin
Version: ${debver}
Section: utils
Priority: optional
Architecture: amd64
Installed-Size: ${size}
Maintainer: Maxwell <maxwell523452@users.noreply.github.com>
Homepage: https://github.com/DeliciousMeatPop/VRCD
Depends: adb | android-tools-adb, libfuse2 | libfuse2t64, libgtk-3-0 | libgtk-3-0t64, libnss3, libnotify4, libxss1, libxtst6, xdg-utils, libatspi2.0-0 | libatspi2.0-0t64, libsecret-1-0, libasound2 | libasound2t64, libuuid1
Description: Android and Meta Quest desktop sideloader (prebuilt AppImage)
 Repackaged official upstream AppImage of VR CyberDeck.
 Packaging: https://github.com/maxwell523452/vr-cyberdeck-bin
EOF
chmod 0644 "$root/DEBIAN/control"

cat > "$root/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = configure ] && command -v udevadm >/dev/null 2>&1; then
  udevadm control --reload-rules || true
  udevadm trigger --subsystem-match=usb --attr-match=idVendor=2833 || true
fi
exit 0
EOF

cat > "$root/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if command -v udevadm >/dev/null 2>&1; then
  udevadm control --reload-rules || true
fi
exit 0
EOF
chmod 0755 "$root/DEBIAN/postinst" "$root/DEBIAN/postrm"

mkdir -p "$outdir"
# xz keeps the package readable on older Debian/Ubuntu releases.
dpkg-deb -Zxz --root-owner-group --build "$root" "$outdir/$deb"

dpkg-deb --info "$outdir/$deb"
echo "built: ${deb}"
