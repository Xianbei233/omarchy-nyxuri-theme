# omarchy-nyxuri-theme

A dynamic **Material You** theme for [Omarchy](https://omarchy.org) — the whole
system recolors itself from whatever wallpaper is active, inspired by
[Nyxuri](https://github.com/ech678/Nyxuri).

Switch the wallpaper (`SUPER + CTRL + SPACE` or `omarchy theme bg next`) and the
bar, terminals, Hyprland borders, GTK color-scheme and browser accent all follow
the new palette — light wallpapers give a light scheme, dark wallpapers dark.

## What it does

```
wallpaper change
   └─ nyx-wallpaper-watch (inotify on Omarchy's background symlink)
        └─ nyx-recolor
             ├─ matugen        → Material You palette from the wallpaper
             ├─ colors.toml    → semantic palette (auto dark/light)
             ├─ hyprland.lua   → border / groupbar colors
             ├─ templates      → kitty, foot, alacritty, ghostty, btop, gum…
             ├─ chromium.theme → browser accent + color-scheme
             └─ omarchy shell  → applyTheme IPC + terminal reload
```

## Install

```sh
git clone https://github.com/<you>/omarchy-nyxuri-theme.git
cd omarchy-nyxuri-theme
./install.sh
```

The installer:

1. installs `matugen`, `inotify-tools`, `ffmpeg`, `imagemagick` (pacman)
2. copies the theme into `~/.config/omarchy/themes/nyxuri`
3. installs `nyx-recolor` / `nyx-wallpaper-watch` into `~/.local/bin`
4. registers the watcher in `~/.config/hypr/autostart.lua`
5. runs `omarchy theme set nyxuri` and recolors for the current wallpaper

## Files

```
theme/
  colors.toml        generated palette (regenerated per wallpaper)
  hyprland.lua       border colors mapped from the palette
  chromium.theme     browser accent (r,g,b)
  preview.png        theme-picker preview
  backgrounds/       bundled wallpapers (stills + video)
bin/
  nyx-recolor        palette generation + push to shell/terminals/GTK/browser
  nyx-wallpaper-watch  inotify daemon, started from hypr autostart
```

## Uninstall

```sh
./uninstall.sh
```

Stops the watcher, removes `~/.local/bin/nyx-*`, the autostart entry, the
theme directory and runtime state; falls back to tokyo-night if nyxuri was
active.

## Credits

- [Nyxuri](https://github.com/ech678/Nyxuri) (originally **NyxNiri**) — the
  Material You-on-Niri desktop whose palette-driven design this theme borrows.
  Wallpapers and the overall look-and-feel come from that project.
- [matugen](https://github.com/InioX/matugen) — Material You palette
  generation.
- [Omarchy](https://omarchy.org) — the shell, theme pipeline and template
  engine this plugs into.

## Notes

- Only activates while the current theme is **nyxuri** — switching to another
  Omarchy theme stops the recolor until you come back.
- Video wallpapers are sampled with ffmpeg (frame at t=2s).
- `omarchy theme set nyxuri` re-copies `theme/`; keep edits there, or edit the
  repo and re-run `./install.sh`.
- The generated `colors.toml` changes with every wallpaper — this is on purpose.
