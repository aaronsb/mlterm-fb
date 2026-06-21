# mlterm-fb

A **framebuffer-only** build of [mlterm](https://github.com/arakiken/mlterm) — a
modern terminal on the bare Linux console (no X, no Wayland, no GTK).

Think "Konsole/kitty experience, but on `/dev/fb0`":

- **24-bit truecolor**
- **Native sixel** graphics
- **Real UTF-8 / multilingual glyph fallback** via fontconfig + freetype
- **TrueType / Nerd Fonts** (antialiased, via cairo)
- **gpm mouse** support (clickable tmux/vim on a tty)

Upstream mlterm builds every frontend (X11, GTK, Wayland, fb, …) and pulls a
large dependency tree. This packages **only** the `fb` frontend, so the runtime
deps are just `freetype2 fontconfig cairo fribidi gpm` — all of which a typical
desktop already has.

## Build

The build runs entirely inside a throwaway Arch container, so the host never
sees the compiler toolchain or `-devel` headers:

```sh
./build.sh        # docker build → extract package/binary to ./out/
```

## Install

```sh
sudo pacman -U out/mlterm-fb-*.pkg.tar.zst
```

Then on a free VT (`Ctrl+Alt+F3`): `mlterm-fb`

## Status

Work in progress — see the project notes. Packaging target: AUR `mlterm-fb`.
