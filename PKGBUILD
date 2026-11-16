
pkgname=vr-cyberdeck-bin
pkgver=2.0.0
pkgrel=1
pkgdesc="Android and Meta Quest desktop sideloader"
arch=('x86_64')
url="https://github.com/DeliciousMeatPop/VRCD"
license=('GPL-3.0-only')
depends=('android-tools' 'fuse2')
options=('!strip')

_appimage="vr-cyberdeck-${pkgver}-x86_64.AppImage"

source=(
  "${_appimage}::https://github.com/DeliciousMeatPop/VRCD/releases/download/v${pkgver}/${_appimage}"
  "https://github.com/DeliciousMeatPop/VRCD/archive/refs/tags/v${pkgver}.tar.gz"
)

sha256sums=('f09917e38c5aacb80a7986069c799b652696cc85055637f1ed55c7bf895c015c'
            'ee5aca11115b3527e4e39e77f89bb904d8030686ebc8f59800ef4d3ce36cf969')

package() {
  install -Dm644 "${srcdir}/VRCD-${pkgver}/LICENSE" \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  # AppImage
  install -Dm755 "${srcdir}/${_appimage}" \
    "${pkgdir}/opt/vr-cyberdeck/vr-cyberdeck.AppImage"

  # Application icon
  install -Dm644 "${srcdir}/VRCD-${pkgver}/resources/icon.png" \
    "${pkgdir}/usr/share/pixmaps/vr-cyberdeck.png"

  # Quest USB permission helper
  install -Dm755 "${srcdir}/VRCD-${pkgver}/scripts/linux-quest-udev.sh" \
    "${pkgdir}/usr/share/vr-cyberdeck/linux-quest-udev.sh"

  # Launch command
  install -d "${pkgdir}/usr/bin"
  cat > "${pkgdir}/usr/bin/vr-cyberdeck" <<'EOF'
#!/bin/sh
exec /opt/vr-cyberdeck/vr-cyberdeck.AppImage "$@"
EOF
  chmod 755 "${pkgdir}/usr/bin/vr-cyberdeck"

  # KDE / desktop application entry
  install -d "${pkgdir}/usr/share/applications"
  cat > "${pkgdir}/usr/share/applications/vr-cyberdeck.desktop" <<'EOF'
[Desktop Entry]
Name=VR CyberDeck
Comment=Android and Meta Quest sideloader
Exec=vr-cyberdeck %U
Icon=vr-cyberdeck
Terminal=false
Type=Application
Categories=Utility;
EOF

  # Documentation and release notes
  install -d "${pkgdir}/usr/share/doc/${pkgname}"
  cat > "${pkgdir}/usr/share/doc/${pkgname}/README.md" <<EOF
# VR CyberDeck

Android and Meta Quest desktop sideloader.

- Upstream: https://github.com/DeliciousMeatPop/VRCD
- Changelog / Release notes: https://github.com/DeliciousMeatPop/VRCD/releases/tag/v${pkgver}

## Quest USB permissions

If your Quest is not detected, run:

sudo sh /usr/share/vr-cyberdeck/linux-quest-udev.sh

Then unplug and reconnect your Quest.
EOF
}
