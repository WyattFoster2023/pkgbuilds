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
# /etc/pacman.conf: enable the official [multilib] repo (needed by steam / lib32-*),
# and add [wyatt] below the official repos:
[multilib]
Include = /etc/pacman.d/mirrorlist

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

- **Login screen (greetd):** `wyatt-hypr-desktop` ships a greetd config (tuigreet -> `start-hyprland`, vt 1),
  a drop-in pointing greetd at it, and a systemd preset. Pacman never enables services, so once per machine:
  `sudo systemctl preset greetd.service` (or `sudo systemctl enable greetd.service`), then reboot.

## Nightly review agent
A scheduled Claude agent runs daily at 03:00 (America/New_York). It covers:
- **Workflow runs:** reviews the last 24h of `build`, `publish`, `image` and `update-check`. On a failure it finds the
  root cause and opens a fix PR; it merges pipeline-only fixes itself, then re-runs and verifies.
- **Update PRs:** reviews every open `update/*` PR opened by `update-check` (PKGBUILD diff, sources and checksums,
  upstream URL, install scripts, anything suspicious), closes superseded ones (newest per package wins; `update-check`
  also closes older ones itself) and posts a short verdict.
- **Never merges** AUR recipe or new-package PRs. Those get signed, so Wyatt merges them after reading the verdict.
- Posts to the project chat only when stuck, when a fix needs Wyatt, or when an update PR needs a decision.

## Security
Public repo + self-hosted runner: workflows never run on `pull_request`; require approval for
outside collaborators. The build job has no secrets; only `publish` (separate runner) holds the GPG key.
