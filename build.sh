#!/usr/bin/env bash
# Build mlterm-fb inside a throwaway Arch container (zero build deps on the host)
# and extract the finished package + .SRCINFO into ./out/.
#
# Usage: ./build.sh
# Install result: sudo pacman -U out/mlterm-fb-*.pkg.tar.zst
set -euo pipefail
cd "$(dirname "$0")"

pkgver=$(awk -F= '/^pkgver=/{print $2}' PKGBUILD)
image="mlterm-fb-pkg:${pkgver}"

echo ">> building $image (container makepkg)…"
docker build -t "$image" -f Dockerfile .

echo ">> extracting artifacts to ./out/…"
rm -rf out && mkdir -p out
cid=$(docker create "$image")
trap 'docker rm -f "$cid" >/dev/null 2>&1 || true' EXIT
docker cp "$cid:/home/build/pkg/." ./out/
# keep only the package, .SRCINFO, and PKGBUILD copy; drop makepkg work dirs
find ./out -mindepth 1 -maxdepth 1 \
     ! -name '*.pkg.tar.zst' ! -name '.SRCINFO' ! -name 'PKGBUILD' \
     -exec rm -rf {} +

echo
echo "Built:"
ls -1 out/*.pkg.tar.zst
echo
echo "Install:  sudo pacman -U $(ls out/*.pkg.tar.zst)"
echo "Run (on a free VT):  mlterm-fb"
