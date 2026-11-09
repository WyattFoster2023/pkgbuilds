#!/usr/bin/env bash
# Runs in the publish job only (holds the signing key). Signs packages, updates
# the db and uploads to the archrepo WebDAV endpoint. Env: GPG_KEY_ID, REPO_URL.
set -euo pipefail
in=${1:-out}; work=$(mktemp -d); url=${REPO_URL:-http://archrepo-publish.archrepo.svc.cluster.local:8081/wyatt/x86_64}
curl -fsS "$url/wyatt.db.tar.zst" -o "$work/wyatt.db.tar.zst" || true
[ -s "$work/wyatt.db.tar.zst" ] && cp "$work/wyatt.db.tar.zst" "$work/wyatt.db" || rm -f "$work/wyatt.db.tar.zst"
for p in "$in"/*.pkg.tar.zst; do
  gpg --batch --yes --detach-sign --local-user "$GPG_KEY_ID" "$p"
  cp "$p" "$p.sig" "$work/"
  repo-add --sign --key "$GPG_KEY_ID" "$work/wyatt.db.tar.zst" "$work/$(basename "$p")"
  curl -fsS -T "$p" "$url/$(basename "$p")"; curl -fsS -T "$p.sig" "$url/$(basename "$p").sig"
done
for f in wyatt.db.tar.zst wyatt.db.tar.zst.sig wyatt.files.tar.zst wyatt.files.tar.zst.sig; do
  curl -fsS -T "$work/$f" "$url/$f"
done
# Object stores/WebDAV do not keep symlinks: upload real copies.
curl -fsS -T "$work/wyatt.db.tar.zst" "$url/wyatt.db"; curl -fsS -T "$work/wyatt.db.tar.zst.sig" "$url/wyatt.db.sig"
curl -fsS -T "$work/wyatt.files.tar.zst" "$url/wyatt.files"; curl -fsS -T "$work/wyatt.files.tar.zst.sig" "$url/wyatt.files.sig"
# TODO(retention): keep the last few versions per package; prune older via DELETE.
