#!/usr/bin/env bash
# Host side: build the package in a clean Arch container. Result lands in ./out
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
rm -rf out
mkdir -p out

docker run --rm \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -v "$PWD:/repo:ro" \
  -v "$PWD/out:/out" \
  archlinux:base-devel \
  bash /repo/scripts/container-build.sh
