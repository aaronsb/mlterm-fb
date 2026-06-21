# Throwaway Arch build environment that runs `makepkg` against ./PKGBUILD and
# leaves the finished package + .SRCINFO in the build user's workdir.
#
# The point: the compiler toolchain and -devel headers live and die in this
# image. The host only ever sees the final .pkg.tar.zst (extracted by build.sh)
# and its small runtime deps.
FROM archlinux:base-devel

# Pre-install the package's build/runtime deps so makepkg can run --nodeps as a
# non-root user (makepkg refuses to run as root).
RUN pacman -Syu --noconfirm --needed \
        freetype2 fontconfig fribidi gpm intltool cairo libssh2 \
    && pacman -Scc --noconfirm

RUN useradd -m build
USER build
WORKDIR /home/build/pkg

COPY --chown=build:build PKGBUILD .
RUN makepkg --noconfirm --nodeps \
    && makepkg --printsrcinfo > .SRCINFO

# Artifacts: /home/build/pkg/mlterm-fb-*.pkg.tar.zst  and  .SRCINFO
