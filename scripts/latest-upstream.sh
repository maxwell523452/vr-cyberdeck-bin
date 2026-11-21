#!/usr/bin/env bash
# Print the version of the latest upstream release (without the leading "v").
# Exit codes: 0 ok, 1 error, 3 release exists but has no x86_64 AppImage yet.
# Needs: gh (authenticated via GH_TOKEN), jq.
set -euo pipefail

upstream="${UPSTREAM_REPO:-DeliciousMeatPop/VRCD}"

release="$(gh api "repos/${upstream}/releases/latest")"
tag="$(jq -er '.tag_name' <<<"$release")"

if [[ ! $tag =~ ^v[0-9]+(\.[0-9]+)*$ ]]; then
  echo "error: unexpected upstream tag: ${tag}" >&2
  exit 1
fi

version="${tag#v}"
asset="vr-cyberdeck-${version}-x86_64.AppImage"

if ! jq -e --arg a "$asset" '.assets | any(.name == $a)' <<<"$release" >/dev/null; then
  echo "upstream release ${tag} has no ${asset} (yet)" >&2
  exit 3
fi

printf '%s\n' "$version"
