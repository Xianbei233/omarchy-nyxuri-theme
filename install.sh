#!/usr/bin/env bash
# omarchy-nyxuri-theme installer
# Installs the Nyxuri theme plus the wallpaper-driven Material You recolor
# pipeline (nyx-recolor + nyx-wallpaper-watch) into a stock Omarchy system.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/nyxuri"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/autostart.lua"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nyxuri"

say() { printf '\033[1;36m::\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; }

command -v omarchy >/dev/null || { err "omarchy not found on PATH"; exit 1; }

# ── 1. Dependencies ────────────────────────────────────────────────
missing=()
for dep in matugen inotifywait ffmpeg magick; do
    command -v "$dep" >/dev/null || missing+=("$dep")
done
if ((${#missing[@]} > 0)); then
    say "Installing dependencies: ${missing[*]}"
    pkexec pacman -S --needed --noconfirm matugen inotify-tools ffmpeg imagemagick
fi
ok "dependencies ready (matugen / inotify-tools / ffmpeg / imagemagick)"

# ── 2. Theme files ──────────────────────────────────────────────────
mkdir -p "$THEME_DIR"
cp -a "$REPO_DIR/theme/." "$THEME_DIR/"
ok "theme installed to $THEME_DIR"

# ── 2b. Wallpapers from Nyxuri's upstream pack ─────────────────────
# Pulled straight from ech678/wallpaper-collection (same source Nyxuri uses),
# never vendored in this repo — the theme only needs the set, not the bytes.
WALLPAPER_REPO="https://github.com/ech678/wallpaper-collection.git"
WALLPAPER_MIRROR="https://gh-proxy.org/https://github.com/ech678/wallpaper-collection.git"
BG_DIR="$THEME_DIR/backgrounds"

fetch_wallpapers() {
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' RETURN
    for url in "$WALLPAPER_REPO" "$WALLPAPER_MIRROR"; do
        say "pulling wallpapers from $url"
        if git clone --depth 1 --filter=blob:none "$url" "$tmp/wc" 2>/dev/null; then
            mkdir -p "$BG_DIR"
            # Flatten: copy stills + video into the theme's backgrounds dir.
            find "$tmp/wc" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
                -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \) \
                -exec cp {} "$BG_DIR/" \;
            rm -rf "$tmp"
            return 0
        fi
    done
    return 1
}

if [[ -d $BG_DIR ]] && compgen -G "$BG_DIR/*" >/dev/null; then
    ok "wallpapers already present in $BG_DIR ($(find "$BG_DIR" -type f | wc -l) files)"
else
    say "fetching wallpapers from Nyxuri's wallpaper-collection"
    fetch_wallpapers || err "wallpaper download failed — install still works, you can add images to $BG_DIR later"
    [[ -d $BG_DIR ]] && ok "downloaded $(find "$BG_DIR" -type f | wc -l) wallpapers"
fi

# ── 3. Scripts ──────────────────────────────────────────────────────
mkdir -p "$BIN_DIR" "$STATE_DIR"
install -m755 "$REPO_DIR/bin/nyx-recolor"        "$BIN_DIR/nyx-recolor"
install -m755 "$REPO_DIR/bin/nyx-wallpaper-watch" "$BIN_DIR/nyx-wallpaper-watch"
ok "installed nyx-recolor + nyx-wallpaper-watch to $BIN_DIR"

# ── 4. Autostart the wallpaper watcher ──────────────────────────────
mkdir -p "$(dirname "$AUTOSTART_FILE")"
if [[ -f $AUTOSTART_FILE ]] && grep -qF "nyx-wallpaper-watch" "$AUTOSTART_FILE"; then
    ok "watcher already in autostart"
else
    cat >> "$AUTOSTART_FILE" <<'EOF'

-- Nyxuri theme: recolor palette whenever the Omarchy wallpaper changes.
o.launch_on_start("~/.local/bin/nyx-wallpaper-watch")
EOF
    ok "added watcher to $AUTOSTART_FILE"
fi

# ── 5. Pick theme + sync colors for the current wallpaper ───────────
say "Applying theme…"
omarchy theme set nyxuri
"$BIN_DIR/nyx-wallpaper-watch" >/dev/null 2>&1 &   # start now, no relog needed
disown
"$BIN_DIR/nyx-recolor" || true

echo
ok "Nyxuri installed. Wallpapers live in $THEME_DIR/backgrounds/"
echo "    cycle with: SUPER + CTRL + SPACE  (or: omarchy theme bg next)"
