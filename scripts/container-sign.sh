#!/usr/bin/env bash
# Runs INSIDE archlinux:base-devel as root, without network.
#   /dist      the unsigned Arch package (read-only)
#   /dist-deb  the unsigned .deb (read-only)
#   /out       receives packages, signatures, repo database and public key
set -euo pipefail

in="${IN:-/dist}"
in_deb="${IN_DEB:-/dist-deb}"
out="${OUT:-/out}"
db=vr-cyberdeck

: "${GPG_PRIVATE_KEY:?}" "${GPG_FINGERPRINT:?}"

shopt -s nullglob
pkgs=("$in"/*.pkg.tar.zst)
if [[ ${#pkgs[@]} -ne 1 ]]; then
  echo "error: expected exactly one package in ${in}, found ${#pkgs[@]}" >&2
  exit 1
fi
pkg="${pkgs[0]}"
pkgname="$(basename "$pkg")"

debs=("$in_deb"/*.deb)
if [[ ${#debs[@]} -ne 1 ]]; then
  echo "error: expected exactly one .deb in ${in_deb}, found ${#debs[@]}" >&2
  exit 1
fi
debname="$(basename "${debs[0]}")"

GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
chmod 700 "$GNUPGHOME"
cleanup() {
  gpgconf --kill gpg-agent >/dev/null 2>&1 || true
  rm -rf "$GNUPGHOME"
}
trap cleanup EXIT

printf '%s\n' "$GPG_PRIVATE_KEY" | gpg --batch --quiet --import

fpr="$(gpg --batch --list-secret-keys --with-colons | awk -F: '$1 == "fpr" { print $10; exit }')"
want="${GPG_FINGERPRINT//[[:space:]]/}"
if [[ -z $fpr || ${fpr^^} != "${want^^}" ]]; then
  echo "error: imported key (${fpr:-none}) does not match GPG_FINGERPRINT" >&2
  exit 1
fi

sign() {
  gpg --batch --yes --detach-sign --no-armor --local-user "$fpr" \
    --output "$1.sig" "$1"
}

install -d "$out"
cp "$pkg" "${debs[0]}" "$out/"
cd "$out"

sign "$pkgname"
sign "$debname"

repo-add "${db}.db.tar.gz" "$pkgname"

for kind in db files; do
  tarball="${db}.${kind}.tar.gz"
  [[ -f $tarball ]] || continue
  sign "$tarball"
  # GitHub release assets cannot be symlinks, so ship real copies.
  rm -f "${db}.${kind}" "${db}.${kind}.sig"
  cp "$tarball" "${db}.${kind}"
  cp "${tarball}.sig" "${db}.${kind}.sig"
done
rm -f ./*.old

gpg --batch --armor --export "$fpr" > "${db}.gpg"

# Verify everything we are about to publish.
for f in "$pkgname" "$debname" "${db}.db.tar.gz" "${db}.db" "${db}.files.tar.gz" "${db}.files"; do
  [[ -f $f ]] || continue
  gpg --batch --verify "${f}.sig" "$f"
done
if ! bsdtar -tf "${db}.db.tar.gz" | grep -q '^vr-cyberdeck-bin-.*/desc$'; then
  echo "error: repository database does not list the package" >&2
  exit 1
fi

if [[ -n ${HOST_UID:-} ]]; then
  chown -R "${HOST_UID}:${HOST_GID:-$HOST_UID}" "$out"
fi
echo "signed with ${fpr}"
