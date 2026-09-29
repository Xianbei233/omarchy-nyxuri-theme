#!/usr/bin/env bash
# Remove the Nyxuri theme and its recolor pipeline.

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/nyxuri"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/autostart.lua"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nyxuri"

say() { printf '\033[1;36m::\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m✓\033[0m %s\n' "$*"; }

# Stop the watcher
pkill -f nyx-wallpaper-watch 2>/dev/null || true
ok "watcher stopped"

# Remove scripts
rm -f "$BIN_DIR/nyx-recolor" "$BIN_DIR/nyx-wallpaper-watch"
ok "removed $BIN_DIR/nyx-*"

# Drop the autostart block (everything between the marker comment and the
# launch line, written by install.sh).
if [[ -f $AUTOSTART_FILE ]]; then
    if grep -qF "nyx-wallpaper-watch" "$AUTOSTART_FILE"; then
        cp "$AUTOSTART_FILE" "$AUTOSTART_FILE.bak.$(date +%s)"
        awk '
            /Nyxuri theme: recolor palette/ { skip = 1 }
            skip && /o\.launch_on_start/ { skip = 0; next }
            !skip
        ' "$AUTOSTART_FILE" > "$AUTOSTART_FILE.tmp" && mv "$AUTOSTART_FILE.tmp" "$AUTOSTART_FILE"
        ok "removed watcher line from $AUTOSTART_FILE (backup saved next to it)"
        hyprctl reload >/dev/null 2>&1 || true
    fi
fi

# Theme files
rm -rf "$THEME_DIR"
ok "removed $THEME_DIR"

# State
rm -rf "$STATE_DIR"
ok "removed $STATE_DIR"

# If nyxuri was the active theme, fall back to tokyo-night.
if [[ "$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)" == "nyxuri" ]]; then
    say "nyxuri was active; switching to tokyo-night"
    omarchy theme set tokyo-night
fi

ok "uninstalled"
