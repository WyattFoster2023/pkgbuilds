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

## Review agents
Two Claude agents look after this repo.

**Nightly workflow review** (scheduled, 02:47 America/New_York)
- Reviews the last 24h of `build`, `publish`, `image` and `update-check`. On a failure it finds the root cause and
  opens a fix PR; it merges pipeline-only fixes itself, then re-runs and verifies (up to 3 attempts, then marks it stuck).
- Does not touch AUR update PRs.

**AUR update PR reviewer** (fired by a GitHub pull request event, not a schedule)
- Runs when a PR from `update-check` (branch `update/*`, title `aur: <name> ...`, including new packages) is opened or
  updated. Closes superseded PRs for the same package (newest wins), reads the PKGBUILD/.SRCINFO diff (sources and
  checksums, upstream URL, install scripts, anything run or downloaded at build time, new dependencies) and posts a
  verdict: safe to merge, needs a look, or do not merge.
- **Never merges, approves or enables auto-merge** on these PRs. They get signed, so Wyatt merges them after reading the verdict.

Both post to the project chat only when something needs Wyatt (stuck run, fix needing his merge, update PR awaiting him, risk found).

## Security
Public repo + self-hosted runner: workflows never run on `pull_request`; require approval for
outside collaborators. The build job has no secrets; only `publish` (separate runner) holds the GPG key.
