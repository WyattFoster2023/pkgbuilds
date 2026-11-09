# pkgbuilds

Private pacman repo `[wyatt]` for Wyatt's Arch laptops: meta-packages, own builds and AUR
builds. Built on a k3s runner, signed in a separate job, served at `https://repo.vpn/wyatt/x86_64`.
Infra side lives in the homelab repo (`docs/archrepo.md`).

```
meta/<name>/   tiny dependency-list packages (wyatt-base -> hypr-desktop -> host-*)
own/<name>/    built from Wyatt's own source (wayle-fork)
aur/<name>/    AUR recipes; changed only by the update-check PRs
```

## Laptop setup (once)
```
curl -O https://repo.vpn/wyatt/wyatt.gpg
sudo pacman-key --add wyatt.gpg && sudo pacman-key --lsign-key <fingerprint>
# /etc/pacman.conf, below the official repos:
[wyatt]
SigLevel = Required DatabaseRequired
Server = https://repo.vpn/wyatt/$arch
sudo pacman -Sy wyatt-host-acer-swift-16   # or wyatt-host-dell-g7-17
```

## How to
- **Edit a meta-package:** change `depends=( ... )` in `meta/<name>/PKGBUILD`, push to `main`.
  The version is the commit count of that folder, set by CI. Removed deps become orphans (`pacman -Qdt`).
- **Add a package:** new folder with a PKGBUILD under `own/` (or `meta/`), push. For AUR: add an
  entry to `nvchecker.toml`, run `update-check`; its PR adds `aur/<name>/`.
- **Roll back:** `sudo pacman -U https://repo.vpn/wyatt/x86_64/<old-package>.pkg.tar.zst`.
- Failures show as red runs in the Actions tab.

## Security
Public repo + self-hosted runner: workflows never run on `pull_request`; require approval for
outside collaborators. The build job has no secrets; only `publish` (separate runner) holds the GPG key.
