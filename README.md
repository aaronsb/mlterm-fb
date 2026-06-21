# mlterm-fb

A **framebuffer-only** build of [mlterm](https://github.com/arakiken/mlterm) — a
modern terminal on the bare Linux console (no X, no Wayland, no GTK).

Think "Konsole/kitty experience, but on `/dev/fb0`":

- **24-bit truecolor**
- **Native sixel** graphics
- **Real UTF-8 / multilingual glyph fallback** via fontconfig + freetype
- **TrueType / Nerd Fonts** (antialiased)
- **Mouse** (evdev): clickable tmux panes, wheel scrollback

Upstream mlterm builds every frontend (X11, GTK, Wayland, fb, …) and pulls a
large dependency tree. This packages **only** the `fb` frontend, so the runtime
deps are just `freetype2 fontconfig fribidi gpm` — all of which a typical
desktop already has. Conflicts with the full `mlterm` package.

## Build

The build runs entirely inside a throwaway Arch container, so the host never
sees the compiler toolchain or `-devel` headers:

```sh
./build.sh        # docker build → extract package to ./out/
```

(`PKGBUILD` is the single source of truth — `build.sh` just runs `makepkg`
inside the container. You can also `makepkg` it directly, or install from AUR.)

## Install

```sh
sudo pacman -U out/mlterm-fb-*.pkg.tar.zst
```

You must be in two groups — **`video`** (framebuffer access) and **`input`**
(evdev keyboard/mouse):

```sh
sudo gpasswd -a "$USER" video input    # then log out/in for it to take effect
```

Run it on a free VT (`Ctrl+Alt+F3`): `mlterm-fb`

## Keyboard on multi-input machines — important

mlterm-fb reads input **directly from evdev** and auto-detects **one** keyboard
by `/sys` name. On a machine with several input devices (multiple keyboards,
wireless receivers, a power button at `event0`, etc.) it often grabs the **wrong
node** — and then *typing does nothing*. The mouse still works because it rides
the kernel's merged `/dev/input/mice`; keyboards have no such merge.

The fix is mlterm's env override `KBD_INPUT_NUM` (1–2 device numbers):

```sh
KBD_INPUT_NUM=8,11 mlterm-fb     # event8 + event11
```

Hardcoding numbers is fragile (USB renumbers across reboots). The robust pattern
is to **resolve keyboards by capability at launch** — match real keyboard-class
devices and pass their *current* event numbers. A drop-in launcher wrapper:

```sh
#!/usr/bin/env bash
# Resolve keyboard event numbers by name + 'kbd' handler, then launch.
set -euo pipefail
match="${MLTERM_KBD_MATCH:-Keyboard}"   # name regex for your keyboard(s)
nums=$(awk -v re="$match" '
  /^N: Name=/ { n=$0; sub(/^N: Name="/,"",n); sub(/"$/,"",n) }
  /^H: Handlers=/ { if (n ~ re && $0 ~ /(^| )kbd( |$)/ && match($0,/event[0-9]+/))
                      print substr($0,RSTART+5,RLENGTH-5) }
' /proc/bus/input/devices | head -2 | paste -sd,)
exec env ${nums:+KBD_INPUT_NUM=$nums} /usr/bin/mlterm-fb "$@"
```

## Configuration

mlterm reads `~/.mlterm/`. Minimal example for a Nerd Font + dark theme:

```ini
# ~/.mlterm/main
fontsize = 24
use_anti_alias = true
use_aafont = true
bg_color = #131415
fg_color = #fcfcfc
use_scrollbar = false
```
```ini
# ~/.mlterm/aafont
DEFAULT = JetBrainsMono Nerd Font Mono
```

## Notes

- Built fb-only via `--with-gui=fb` (no xlib/gtk/wayland frontends).
- mlterm 3.9.4 predates GCC 14 promoting some legacy-C warnings to errors; the
  PKGBUILD downgrades `-Wincompatible-pointer-types` & friends so it compiles.
