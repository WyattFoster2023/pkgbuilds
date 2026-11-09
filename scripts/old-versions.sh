#!/usr/bin/env bash
# Write old_ver.json from the pkgver of each recipe present in aur/ and own/.
# A package listed in nvchecker.toml but with no folder yet has no entry, so
# nvcmp reports it as new (None -> x) and update-check seeds it with a PR.
set -euo pipefail
python3 - <<'P'
import glob, json, re, os
d = {}
for f in glob.glob("aur/*/PKGBUILD") + glob.glob("own/*/PKGBUILD"):
    m = re.search(r"^pkgver=(\S+)", open(f).read(), re.M)
    if m:
        d[os.path.basename(os.path.dirname(f))] = {"version": m.group(1).strip("'\"")}
json.dump({"version": 2, "data": d}, open("old_ver.json", "w"))
P
