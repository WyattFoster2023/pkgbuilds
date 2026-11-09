#!/usr/bin/env bash
# Print package dirs (meta/x own/x aur/x) touched between $1 and HEAD, one per line.
# Dependencies between packages are built in the order meta-last: own/aur first.
set -euo pipefail
base=${1:-HEAD~1}
git diff --name-only "$base" HEAD -- meta own aur | awk -F/ 'NF>=3{print $1"/"$2}' | sort -u |
  awk '{o=($0 ~ /^meta/)?1:0; print o" "$0}' | sort -n | cut -d' ' -f2 |
  while read -r d; do [ -f "$d/PKGBUILD" ] && echo "$d"; done
