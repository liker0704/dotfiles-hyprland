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
QS_JSON="$HOME/.local/state/quickshell/generated/colors.json"
MD3_CACHE_DIR="$HOME/.cache/wallpaper-md3"

# Fast path: cp from per-wallpaper cache if available. Hash uses same scheme
# as theme-cache-wallpapers / WallpaperSelect (md5 of full path, first 12 chars).
hash=$(echo "$WALLPAPER" | md5sum | cut -c1-12)
md3_cache="$MD3_CACHE_DIR/${hash}.json"

if [[ -f "$md3_cache" ]]; then
  mkdir -p "$(dirname "$QS_JSON")"
  cp "$md3_cache" "$QS_JSON"
  source_label="cached"
else
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

  # Save freshly-generated JSON to cache for next time
  if [[ -f "$QS_JSON" ]]; then
    mkdir -p "$MD3_CACHE_DIR"
    cp "$QS_JSON" "$md3_cache"
  fi
fi

# Update accent_secondary in palette.conf with matugen's harmonized secondary.
# accent itself stays as wallust pick (the seed) — that's the source tone.
if [[ -f "$QS_JSON" && -f "$PALETTE" ]]; then
  secondary=$(python3 -c "import json,sys; print(json.load(open('$QS_JSON'))['md3'].get('secondary','').lstrip('#'))" 2>/dev/null)
  if [[ -n "$secondary" ]]; then
    sed -i "s/^accent_secondary=.*/accent_secondary=$secondary/" "$PALETTE"
  fi
fi

echo -e "  \033[0;32mmatugen\033[0m ($source_label)"
