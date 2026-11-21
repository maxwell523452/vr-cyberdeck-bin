#!/usr/bin/env bash
# Host side: upload the signed package and the repository database.
#   - release $TAG (e.g. v2.0.0-1) keeps one signed package per version
#   - release "pacman-repo" always holds only the newest package + database
# Needs env: GH_TOKEN, GH_REPO, TAG. Needs: gh.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
: "${GH_TOKEN:?}" "${GH_REPO:?}" "${TAG:?}"

repo_tag=pacman-repo
dir=repo-out

die() { echo "error: $*" >&2; exit 1; }

[[ $TAG =~ ^v[0-9]+(\.[0-9]+)*-[0-9]+$ ]] || die "unexpected tag: ${TAG}"

shopt -s nullglob
pkgs=("$dir"/*.pkg.tar.zst)
[[ ${#pkgs[@]} -eq 1 ]] || die "expected exactly one package in ${dir}"
pkg="$(basename "${pkgs[0]}")"
[[ $pkg == "vr-cyberdeck-bin-${TAG#v}-x86_64.pkg.tar.zst" ]] \
  || die "package ${pkg} does not match tag ${TAG}"
[[ -f $dir/$pkg.sig ]] || die "missing signature for ${pkg}"

sha="$(sha256sum "$dir/$pkg" | cut -d' ' -f1)"
notes="Arch package for VR CyberDeck ${TAG#v}, repackaged from the official upstream .deb.

sha256: \`${sha}\`
Upstream: https://github.com/DeliciousMeatPop/VRCD/releases/tag/${TAG%-*}"

ensure_release() { # tag title notes [files...]
  local tag="$1" title="$2" body="$3" rc=0
  shift 3
  scripts/gh-release-exists.sh "$tag" || rc=$?
  case $rc in
    0) [[ $# -eq 0 ]] || gh release upload "$tag" "$@" --clobber ;;
    1) gh release create "$tag" "$@" --title "$title" --notes "$body" \
         --target "${GITHUB_SHA:-main}" ;;
    *) die "could not query release ${tag}" ;;
  esac
}

# 1) versioned release: package + signature
ensure_release "$TAG" "VR CyberDeck ${TAG#v}" "$notes" "$dir/$pkg" "$dir/$pkg.sig"

# 2) repository release: package first, so the database never points at a missing file
ensure_release "$repo_tag" "Pacman repository" \
  "Signed pacman repository. See the README for setup instructions."
gh release upload "$repo_tag" "$dir/$pkg" "$dir/$pkg.sig" --clobber

meta=("$dir"/vr-cyberdeck.db* "$dir"/vr-cyberdeck.files* "$dir"/vr-cyberdeck.gpg)
[[ ${#meta[@]} -ge 5 ]] || die "repository database files are missing"
gh release upload "$repo_tag" "${meta[@]}" --clobber

# 3) drop assets of older versions from the repository release
keep="$(find "$dir" -maxdepth 1 -type f -printf '%f\n')"
while IFS= read -r name; do
  [[ -n $name ]] || continue
  if ! grep -Fxq -- "$name" <<<"$keep"; then
    echo "removing stale asset: ${name}"
    gh release delete-asset "$repo_tag" "$name" --yes
  fi
done < <(gh release view "$repo_tag" --json assets --jq '.assets[].name')

echo "published ${TAG}"
