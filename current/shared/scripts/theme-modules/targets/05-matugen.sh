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

# Use wallust-picked accent (palette.conf) as MD3 seed.
# Wallust extracts the visually dominant color from the wallpaper (saturation-
# weighted), then matugen derives all MD3 tonal roles around THAT seed via HCT.
# Result: one unified hue family (accent + secondary + surfaces all share the
# wallust-picked tone). Falls back to image-based scheme if no accent yet.
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
seed=""
if [[ -f "$PALETTE" ]]; then
  seed=$(grep '^accent=' "$PALETTE" | head -1 | cut -d= -f2 | tr -d ' \r\n')
fi

if [[ -n "$seed" ]]; then
  if [[ -f "$MATUGEN_CONFIG" ]]; then
    matugen color hex "#$seed" -c "$MATUGEN_CONFIG" 2>/dev/null
  else
    matugen color hex "#$seed" 2>/dev/null
  fi
  source_label="seed: #$seed"
else
  if [[ -f "$MATUGEN_CONFIG" ]]; then
    matugen image "$WALLPAPER" -c "$MATUGEN_CONFIG" 2>/dev/null
  else
    matugen image "$WALLPAPER" 2>/dev/null
  fi
  source_label="image: $(basename "$WALLPAPER")"
fi

# Update accent_secondary in palette.conf with matugen's harmonized secondary.
# accent itself stays as wallust pick (the seed) — that's the source tone.
QS_JSON="$HOME/.local/state/quickshell/generated/colors.json"
if [[ -f "$QS_JSON" && -f "$PALETTE" ]]; then
  secondary=$(python3 -c "import json,sys; print(json.load(open('$QS_JSON'))['md3'].get('secondary','').lstrip('#'))" 2>/dev/null)
  if [[ -n "$secondary" ]]; then
    sed -i "s/^accent_secondary=.*/accent_secondary=$secondary/" "$PALETTE"
  fi
fi

echo -e "  \033[0;32mmatugen\033[0m ($source_label)"
