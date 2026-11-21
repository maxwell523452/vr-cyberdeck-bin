#!/usr/bin/env bash
# Runs INSIDE archlinux:base-devel as root.
#   /repo  read-only checkout of this repository
#   /out   receives the built package
set -euo pipefail

src="${SRC:-/repo}"
out="${OUT:-/out}"
build=/build

pacman -Syu --noconfirm --needed namcap

id builder >/dev/null 2>&1 || useradd --create-home builder
install -d -o builder -g builder "$build"
install -m 644 -o builder -g builder "$src/PKGBUILD" "$build/"
install -m 644 -o builder -g builder "$src"/*.rules "$build/"

# --nodeps: only runtime dependencies, nothing is compiled.
# makepkg verifies every checksum in sha256sums before building.
runuser -l builder -c "cd '$build' && makepkg --cleanbuild --nodeps --noconfirm"

shopt -s nullglob
pkgs=("$build"/*.pkg.tar.zst)
if [[ ${#pkgs[@]} -ne 1 ]]; then
  echo "error: expected exactly one package, found ${#pkgs[@]}" >&2
  exit 1
fi
pkg="${pkgs[0]}"

# Informational only: namcap is noisy for repackaged binaries.
namcap "$build/PKGBUILD" || true
namcap "$pkg" || true

"$src/scripts/verify-package.sh" "$pkg"

install -m 644 "$pkg" "$out/"
if [[ -n ${HOST_UID:-} ]]; then
  chown -R "${HOST_UID}:${HOST_GID:-$HOST_UID}" "$out"
fi
echo "built: $(basename "$pkg")"
