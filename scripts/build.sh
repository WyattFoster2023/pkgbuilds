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
sudo pacman -Sy --noconfirm
( cd "$dir" && namcap PKGBUILD && makepkg --syncdeps --noconfirm --cleanbuild --skippgpcheck \
    PKGDEST="$out" )
