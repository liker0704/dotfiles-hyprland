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
# Detect dark/light mode from full wallpaper (Lab L mean, threshold 0.55).
MODE="dark"
if command -v theme-detect-mode &>/dev/null; then
  MODE=$(theme-detect-mode "$WALLPAPER" 2>/dev/null)
  [[ -z "$MODE" ]] && MODE="dark"
fi

# Cache key: hash of wallpaper path + mode. Was keyed by wallust's accent_seed
# hex, but wallust picks saturated outliers (tiny peach face) over dominant
# blue sky. matugen's own extractor uses Google Material You's Score() which
# weights pixel frequency + perceptual desirability — produces correct
# dominant-color seed directly from the image.
md3_key=$(echo -n "$WALLPAPER" | md5sum | cut -c1-12)
md3_cache="$MD3_CACHE_DIR/${md3_key}-${MODE}.json"

if [[ -f "$md3_cache" ]]; then
  mkdir -p "$(dirname "$QS_JSON")"
  cp "$md3_cache" "$QS_JSON"
  source_label="cached: $md3_key ($MODE)"
else
  # Let matugen extract seed directly from the wallpaper.
  # --source-color-index 0 = most dominant by MD3 Score algorithm.
  if [[ -f "$MATUGEN_CONFIG" ]]; then
    matugen image "$WALLPAPER" -m "$MODE" --source-color-index 0 -c "$MATUGEN_CONFIG" 2>/dev/null
  else
    matugen image "$WALLPAPER" -m "$MODE" --source-color-index 0 2>/dev/null
  fi
  source_label="image: $(basename "$WALLPAPER") ($MODE)"

  # Save to per-wallpaper cache
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
  # Pull all relevant MD3 fields + apply Fix 1 (accent contrast boost)
  read -r primary secondary bg bg_light bg_highlight fg fg_dim fg_muted border < <(python3 -c "
import json, colorsys
d = json.load(open('$QS_JSON'))['md3']
def s(k): return d.get(k, '').lstrip('#')
def L(h):
    r,g,b = [int(h[i:i+2],16)/255 for i in (0,2,4)]
    return colorsys.rgb_to_hls(r,g,b)[1]

primary, secondary = s('primary'), s('secondary')
bg_v = s('surface'); fg_v = s('on_surface')

# Fix 1: if accent vs surface contrast is too low, boost lightness toward
# the readable end (light for dark theme, dark for light theme).
if primary and bg_v:
    bg_l = L(bg_v); pl = L(primary)
    if abs(pl - bg_l) < 0.30:
        ph = colorsys.rgb_to_hls(*[int(primary[i:i+2],16)/255 for i in (0,2,4)])[0]
        ps = colorsys.rgb_to_hls(*[int(primary[i:i+2],16)/255 for i in (0,2,4)])[2]
        new_l = min(0.78, bg_l + 0.55) if bg_l < 0.5 else max(0.25, bg_l - 0.55)
        r,g,b = colorsys.hls_to_rgb(ph, new_l, max(ps, 0.40))
        primary = ''.join(f'{int(c*255):02x}' for c in (r,g,b))

print(primary, secondary,
      bg_v, s('surface_container_low'), s('surface_container_high'),
      fg_v, s('on_surface_variant'),
      s('outline'), s('outline_variant'))
" 2>/dev/null)

  # Testing: bg/fg also from matugen. Revert to wallust later if it hurts
  # readability or looks too "designed" for terminal use.
  for kv in "accent=$primary" "accent_secondary=$secondary" \
            "bg=$bg" "fg=$fg" \
            "bg_light=$bg_light" "bg_highlight=$bg_highlight" \
            "fg_dim=$fg_dim" "fg_muted=$fg_muted" "border=$border"; do
    key="${kv%%=*}"; val="${kv#*=}"
    [[ -z "$val" ]] && continue
    sed -i "s/^${key}=.*/${key}=${val}/" "$PALETTE"
    C[$key]="$val"
  done
fi

echo -e "  \033[0;32mmatugen\033[0m ($source_label)"
