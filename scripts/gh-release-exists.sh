#!/usr/bin/env bash
# Does a GitHub release with this tag exist in $GH_REPO?
# Exit codes: 0 exists, 1 does not exist, 2 API/auth/network error.
set -uo pipefail

tag="${1:?usage: gh-release-exists.sh TAG}"
: "${GH_REPO:?GH_REPO is not set}"

if out="$(gh api "repos/${GH_REPO}/releases/tags/${tag}" 2>&1)"; then
  exit 0
fi
if grep -q 'HTTP 404' <<<"$out"; then
  exit 1
fi
echo "$out" >&2
exit 2
