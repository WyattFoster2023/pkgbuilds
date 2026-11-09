# Build image for pkgbuilds CI. Rebuilt weekly (rolling Arch drifts fast).
FROM archlinux:base-devel
RUN pacman -Syu --noconfirm --needed git pacman-contrib namcap nvchecker rust cargo clang sudo github-cli rsync && \
    useradd -m builder && \
    echo 'builder ALL=(root) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder && \
    sed -i 's/^#\?PACKAGER=.*/PACKAGER="Wyatt Foster <wyattfosteredu@gmail.com>"/; s/^#\?MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf && \
    pacman -Scc --noconfirm
# NOTE: the [wyatt] repo is NOT added here: pacman fails every -Sy while it is
# empty/unreachable. scripts/build.sh adds it at build time when reachable.
USER builder
WORKDIR /home/builder
# aurutils is itself an AUR package: build it once here.
RUN git clone --depth 1 https://aur.archlinux.org/aurutils.git /tmp/aurutils && \
    cd /tmp/aurutils && makepkg --syncdeps --noconfirm --install && rm -rf /tmp/aurutils
