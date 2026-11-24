# Maintainer: Maxwell
# Upstream:   https://github.com/DeliciousMeatPop/VRCD

pkgname=vr-cyberdeck-bin
pkgver=2.0.1
pkgrel=1
pkgdesc='Android and Meta Quest desktop sideloader (repackaged upstream .deb)'
arch=('x86_64')
url='https://github.com/DeliciousMeatPop/VRCD'
license=('GPL-3.0-only')
depends=(
  'android-tools'
  # taken from the Depends: line of upstream's .deb
  'at-spi2-core' 'gtk3' 'libnotify' 'libsecret' 'libxss' 'libxtst'
  'nss' 'util-linux-libs' 'xdg-utils'
  # not listed upstream, but Electron needs it for audio
  'alsa-lib'
)
optdepends=(
  'libappindicator-gtk3: tray icon support'
  'android-udev: udev rules for Android phones (Quest rules are included)'
)
provides=('vr-cyberdeck')
conflicts=('vr-cyberdeck')
options=('!strip' '!debug')

_upstream='DeliciousMeatPop/VRCD'
_deb="vr-cyberdeck-${pkgver}-amd64.deb"
_raw="https://raw.githubusercontent.com/${_upstream}/v${pkgver}"

noextract=("${_deb}")
source=(
  "${_deb}::https://github.com/${_upstream}/releases/download/v${pkgver}/${_deb}"
  "upstream-LICENSE::${_raw}/LICENSE"
  '51-vr-cyberdeck-quest.rules'
)

# Filled in by scripts/update-pkgbuild.sh - do not edit by hand.
sha256sums=('df3508bc069af8fc70ff1baa2ccd0e5753442e7a497e1a55a1e9d547ce14bdd9'
            'a11818586bf0e1cbdca5e670fd59773a5d741c329bdf9ab33cc00ff3ff9d8416'
            '8959cea0641386792b675919b29f150319434f5b2a4fa367cd510e7accf56b49')

prepare() {
  local magic listing data
  magic="$(head -c 7 "${srcdir}/${_deb}")"
  if [[ ${magic} != '!<arch>' ]]; then
    error 'the downloaded file is not a .deb (ar archive)'
    return 1
  fi
  if ! grep -q 'GNU GENERAL PUBLIC LICENSE' "${srcdir}/upstream-LICENSE"; then
    error 'upstream license is no longer GPL-3.0 - review the license= field'
    return 1
  fi

  mkdir -p "${srcdir}/deb"
  bsdtar -xf "${srcdir}/${_deb}" -C "${srcdir}/deb"

  data=("${srcdir}"/deb/data.tar.*)
  if [[ ${#data[@]} -ne 1 || ! -f ${data[0]} ]]; then
    error 'expected exactly one data.tar.* inside the .deb'
    return 1
  fi
  listing="$(bsdtar -tf "${data[0]}")"
  if ! grep -Fxq './opt/VR CyberDeck/vr-cyberdeck' <<<"${listing}"; then
    error 'unexpected .deb layout: upstream moved the application directory'
    return 1
  fi
}

package() {
  local data
  data=("${srcdir}"/deb/data.tar.*)
  bsdtar -xpf "${data[0]}" -C "${pkgdir}" --no-same-owner

  # Debian-only leftovers
  rm -rf "${pkgdir}/usr/share/doc"
  rm -f "${pkgdir}/opt/VR CyberDeck/resources/apparmor-profile"

  # Directory names with spaces are a pain: use /opt/vr-cyberdeck
  mv "${pkgdir}/opt/VR CyberDeck" "${pkgdir}/opt/vr-cyberdeck"
  sed -i 's|/opt/VR CyberDeck/|/opt/vr-cyberdeck/|g' \
    "${pkgdir}/usr/share/applications/vr-cyberdeck.desktop"

  # Electron's sandbox uses user namespaces (enabled on Arch kernels), so the
  # helper must not be setuid. Upstream's postinst makes the same choice.
  chmod 755 "${pkgdir}/opt/vr-cyberdeck/chrome-sandbox"

  install -d "${pkgdir}/usr/bin"
  ln -s /opt/vr-cyberdeck/vr-cyberdeck "${pkgdir}/usr/bin/vr-cyberdeck"

  install -Dm644 "${srcdir}/upstream-LICENSE" \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
  install -Dm644 "${srcdir}/51-vr-cyberdeck-quest.rules" \
    "${pkgdir}/usr/lib/udev/rules.d/51-vr-cyberdeck-quest.rules"
}
