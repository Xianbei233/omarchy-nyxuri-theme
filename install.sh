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
