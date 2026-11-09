#!/usr/bin/env bash
# Fresh container, full system update, then ldd every binary of source-built
# packages (own/*); trigger a rebuild for any with missing libraries.
set -euo pipefail
for d in own/*/; do n=$(basename "$d")
  if docker run --rm "$REG/archbuild:latest" bash -c "
      sudo pacman -Syu --noconfirm >/dev/null
      sudo pacman -S --noconfirm --needed $n >/dev/null 2>&1 || exit 0
      pacman -Ql $n | awk '{print \$2}' | grep -E '^/usr/bin/[^/]+$' | xargs -r ldd 2>/dev/null | grep -q 'not found' && exit 1 || exit 0"; then
    echo "$n ok"; else echo "$n has missing libs, rebuilding"; gh workflow run build.yml -f pkg="own/$n"; fi
done
