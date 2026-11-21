# Maintainer: Maxwell
# Upstream:   https://github.com/DeliciousMeatPop/VRCD

pkgname=vr-cyberdeck-bin
pkgver=2.0.0
pkgrel=1
pkgdesc='Android and Meta Quest desktop sideloader (prebuilt AppImage)'
arch=('x86_64')
url='https://github.com/DeliciousMeatPop/VRCD'
license=('GPL-3.0-only')
depends=(
  'android-tools'
  'fuse2'
  # Electron runtime libraries the AppImage takes from the host
  'alsa-lib' 'at-spi2-core' 'gtk3' 'libnotify' 'libsecret'
  'libxss' 'libxtst' 'nss' 'util-linux-libs' 'xdg-utils'
)
optdepends=('android-udev: udev rules for Android phones (Quest rules are included)')
provides=('vr-cyberdeck')
conflicts=('vr-cyberdeck')
options=('!strip' '!debug')

_upstream='DeliciousMeatPop/VRCD'
_appimage="vr-cyberdeck-${pkgver}-x86_64.AppImage"
_raw="https://raw.githubusercontent.com/${_upstream}/v${pkgver}"

source=(
  "${_appimage}::https://github.com/${_upstream}/releases/download/v${pkgver}/${_appimage}"
  "upstream-LICENSE::${_raw}/LICENSE"
  "upstream-icon.png::${_raw}/resources/icon.png"
  '51-vr-cyberdeck-quest.rules'
)

# Filled in by scripts/update-pkgbuild.sh - do not edit by hand.
sha256sums=('f09917e38c5aacb80a7986069c799b652696cc85055637f1ed55c7bf895c015c'
            'a11818586bf0e1cbdca5e670fd59773a5d741c329bdf9ab33cc00ff3ff9d8416'
            'b49696cc5ad858146814b6ce5f033b1c1277a9e79802d8469e7b0ffe1cbf49c7'
            '8959cea0641386792b675919b29f150319434f5b2a4fa367cd510e7accf56b49')

prepare() {
  local magic
  magic="$(head -c 4 "${srcdir}/${_appimage}" | od -An -tx1 | tr -d ' \n')"
  if [[ ${magic} != 7f454c46 ]]; then
    error 'the downloaded AppImage is not an ELF executable'
    return 1
  fi
  if ! grep -q 'GNU GENERAL PUBLIC LICENSE' "${srcdir}/upstream-LICENSE"; then
    error 'upstream license is no longer GPL-3.0 - review the license= field'
    return 1
  fi
}

package() {
  install -Dm755 "${srcdir}/${_appimage}" \
    "${pkgdir}/opt/vr-cyberdeck/vr-cyberdeck.AppImage"
  install -Dm644 "${srcdir}/upstream-icon.png" \
    "${pkgdir}/usr/share/pixmaps/vr-cyberdeck.png"
  install -Dm644 "${srcdir}/upstream-LICENSE" \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  install -Dm644 "${srcdir}/51-vr-cyberdeck-quest.rules" \
    "${pkgdir}/usr/lib/udev/rules.d/51-vr-cyberdeck-quest.rules"

  install -d "${pkgdir}/usr/bin"
  cat > "${pkgdir}/usr/bin/vr-cyberdeck" <<'EOF'
#!/bin/sh
exec /opt/vr-cyberdeck/vr-cyberdeck.AppImage "$@"
EOF
  chmod 755 "${pkgdir}/usr/bin/vr-cyberdeck"

  install -d "${pkgdir}/usr/share/applications"
  cat > "${pkgdir}/usr/share/applications/vr-cyberdeck.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=VR CyberDeck
Comment=Android and Meta Quest sideloader
Exec=vr-cyberdeck
Icon=vr-cyberdeck
Terminal=false
Categories=Utility;
Keywords=Quest;Android;ADB;Sideload;
EOF
}
