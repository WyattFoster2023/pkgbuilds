#!/usr/bin/env bash
# Run INSIDE the build image as `builder`. Builds one package dir into ./out.
set -euo pipefail
dir=$1; out=${2:-$PWD/out}
mkdir -p "$out"
# Meta-packages: version is derived from the commit count so nobody forgets to bump.
if [[ $dir == meta/* ]]; then
  n=$(git rev-list --count HEAD -- "$dir")
  sed -i "s/^pkgver=.*/pkgver=$n/; s/^pkgrel=.*/pkgrel=1/" "$dir/PKGBUILD"
fi
# Meta-packages only name dependencies (they contain no files), so never install
# them to build; this also lets them build before their AUR deps are published.
flags=(--syncdeps)
[[ $dir == meta/* ]] && flags=(--nodeps)
# Optional read-only access to our own repo for packages that depend on each other.
# /etc/pacman.conf is owned by builder in the image (sudoers only allows pacman).
# SigLevel Never: the repo is signed with a key the image does not have, and it is
# only reachable inside the cluster.
if [ -n "${WYATT_REPO_URL:-}" ] && curl -fsS -o /dev/null "$WYATT_REPO_URL/wyatt.db"; then
  printf '\n[wyatt]\nSigLevel = Never\nServer = %s\n' "$WYATT_REPO_URL" >> /etc/pacman.conf
fi
sudo pacman -Sy --noconfirm
( cd "$dir" && namcap PKGBUILD && makepkg "${flags[@]}" --noconfirm --cleanbuild --skippgpcheck \
    PKGDEST="$out" )
