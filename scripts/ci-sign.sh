#!/usr/bin/env bash
# Host side: sign ./dist/*.pkg.tar.zst and build the signed pacman database.
# The container has NO network access while the private key is loaded.
# Needs env: GPG_PRIVATE_KEY (armored), GPG_FINGERPRINT.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
: "${GPG_PRIVATE_KEY:?GPG_PRIVATE_KEY is not set}"
: "${GPG_FINGERPRINT:?GPG_FINGERPRINT is not set}"

rm -rf repo-out
mkdir -p repo-out

docker run --rm --network none \
  -e GPG_PRIVATE_KEY -e GPG_FINGERPRINT \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -v "$PWD/dist:/dist:ro" \
  -v "$PWD/scripts:/scripts:ro" \
  -v "$PWD/repo-out:/out" \
  archlinux:base-devel \
  bash /scripts/container-sign.sh
