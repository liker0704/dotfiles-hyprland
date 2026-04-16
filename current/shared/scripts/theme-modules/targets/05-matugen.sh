#!/bin/bash
# Matugen integration — runs BEFORE other targets (hence 05- prefix).
# Only fires when engine=matugen in ~/.config/theme/config.
# Extracts colors from current wallpaper and regenerates palette.conf.

THEME_CONFIG="$HOME/.config/theme/config"
PALETTE="$HOME/.config/theme/palette.conf"

# Skip if engine is not matugen
if [[ -f "$THEME_CONFIG" ]]; then
  engine=$(grep -E '^engine=' "$THEME_CONFIG" 2>/dev/null | cut -d= -f2)
fi

if [[ "${engine:-wallust}" != "matugen" ]]; then
  return 0 2>/dev/null || exit 0
fi

# Check matugen is installed
if ! command -v matugen &>/dev/null; then
  echo "  matugen not installed — skipping (paru -S matugen)"
  return 0 2>/dev/null || exit 0
fi

# Get current wallpaper
WALLPAPER=""
if command -v swww &>/dev/null; then
  WALLPAPER=$(swww query 2>/dev/null | head -1 | grep -oP 'image: \K.*')
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
  # Fallback: check .current_wallpaper
  WALLPAPER=$(cat "$HOME/.config/rofi/.current_wallpaper" 2>/dev/null)
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
  echo "  no wallpaper found — skipping matugen"
  return 0 2>/dev/null || exit 0
fi

# Run matugen (if config exists)
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
if [[ -f "$MATUGEN_CONFIG" ]]; then
  matugen image "$WALLPAPER" -c "$MATUGEN_CONFIG" 2>/dev/null
else
  matugen image "$WALLPAPER" 2>/dev/null
fi

echo -e "  \033[0;32mmatugen\033[0m (from: $(basename "$WALLPAPER"))"
