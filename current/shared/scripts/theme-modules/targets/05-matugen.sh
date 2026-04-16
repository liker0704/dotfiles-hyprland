#!/bin/bash
# Matugen integration — runs BEFORE other targets (hence 05- prefix).
# Always generates Material Design 3 palette alongside wallust.
# wallust still owns terminal ANSI (kitty/tmux); matugen drives MD3
# tonal roles for Quickshell UI via ~/.config/matugen/config.toml.

PALETTE="$HOME/.config/theme/palette.conf"

# Check matugen is installed
if ! command -v matugen &>/dev/null; then
  echo "  matugen not installed — skipping (paru -S matugen)"
  return 0 2>/dev/null || exit 0
fi

# Get current wallpaper of the FOCUSED monitor (not the first one swww lists).
# On multi-monitor setups, swww query may list a different monitor's wallpaper
# than the one user just changed via Super+W.
WALLPAPER=""
if command -v swww &>/dev/null && command -v hyprctl &>/dev/null; then
  focused=$(hyprctl monitors -j 2>/dev/null | python3 -c "
import json, sys
mons = json.load(sys.stdin)
print(next((m['name'] for m in mons if m.get('focused')), ''))
" 2>/dev/null)
  if [[ -n "$focused" ]]; then
    WALLPAPER=$(swww query 2>/dev/null | grep -F "$focused:" | grep -oP 'image: \K.*')
  fi
fi

# Fallback: first monitor swww reports
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
  WALLPAPER=$(swww query 2>/dev/null | head -1 | grep -oP 'image: \K.*')
fi

# Last fallback: rofi current marker
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
  WALLPAPER=$(cat "$HOME/.config/rofi/.current_wallpaper" 2>/dev/null)
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
  echo "  no wallpaper found — skipping matugen"
  return 0 2>/dev/null || exit 0
fi

# MD3 cache keyed by ACCENT HEX, not wallpaper path.
# Matugen output is deterministic from seed color: same accent → same MD3.
# This sidesteps multi-monitor focus confusion (different monitors may show
# different wallpapers, but the wallpaper picker just wrote the right accent
# into palette.conf — that's our source of truth).
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
QS_JSON="$HOME/.local/state/quickshell/generated/colors.json"
MD3_CACHE_DIR="$HOME/.cache/matugen-by-accent"

# Read SEED (wallust raw pick, stable). Falls back to accent for old caches.
seed=""
if [[ -f "$PALETTE" ]]; then
  seed=$(grep '^accent_seed=' "$PALETTE" | head -1 | cut -d= -f2 | tr -d ' \r\n#' | tr 'A-F' 'a-f')
  if [[ -z "$seed" ]]; then
    seed=$(grep '^accent=' "$PALETTE" | head -1 | cut -d= -f2 | tr -d ' \r\n#' | tr 'A-F' 'a-f')
  fi
fi

if [[ -z "$seed" ]]; then
  echo "  no accent_seed in palette.conf — skipping matugen"
  return 0 2>/dev/null || exit 0
fi

# Detect dark/light mode from full wallpaper (Lab L mean, threshold 0.55).
MODE="dark"
if command -v theme-detect-mode &>/dev/null; then
  MODE=$(theme-detect-mode "$WALLPAPER" 2>/dev/null)
  [[ -z "$MODE" ]] && MODE="dark"
fi

# Cache key includes mode so light/dark seeds don't collide
md3_cache="$MD3_CACHE_DIR/${seed}-${MODE}.json"

if [[ -f "$md3_cache" ]]; then
  mkdir -p "$(dirname "$QS_JSON")"
  cp "$md3_cache" "$QS_JSON"
  source_label="cached: #$seed ($MODE)"
else
  if [[ -f "$MATUGEN_CONFIG" ]]; then
    matugen color hex "#$seed" -m "$MODE" -c "$MATUGEN_CONFIG" 2>/dev/null
  else
    matugen color hex "#$seed" -m "$MODE" 2>/dev/null
  fi
  source_label="seed: #$seed ($MODE)"

  # Save to per-accent cache
  if [[ -f "$QS_JSON" ]]; then
    mkdir -p "$MD3_CACHE_DIR"
    cp "$QS_JSON" "$md3_cache"
  fi
fi

# Replace palette.conf accent + accent_secondary with matugen's MD3-corrected
# primary/secondary. wallust pick was the SEED (extracted dominant color) but
# matugen normalizes lightness/contrast for dark mode — we want all consumers
# (kitty/tmux/zen/gtk/Quickshell bar) using the same final hex.
if [[ -f "$QS_JSON" && -f "$PALETTE" ]]; then
  primary=$(python3 -c "import json,sys; print(json.load(open('$QS_JSON'))['md3'].get('primary','').lstrip('#'))" 2>/dev/null)
  secondary=$(python3 -c "import json,sys; print(json.load(open('$QS_JSON'))['md3'].get('secondary','').lstrip('#'))" 2>/dev/null)
  if [[ -n "$primary" ]]; then
    sed -i "s/^accent=.*/accent=$primary/" "$PALETTE"
  fi
  if [[ -n "$secondary" ]]; then
    sed -i "s/^accent_secondary=.*/accent_secondary=$secondary/" "$PALETTE"
  fi
fi

echo -e "  \033[0;32mmatugen\033[0m ($source_label)"
