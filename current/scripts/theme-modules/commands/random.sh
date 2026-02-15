#!/usr/bin/env bash
# cmd_random — pick a random quality theme

cmd_random() {
  local filter="" no_font=""
  for arg in "$@"; do
    case "$arg" in
      --no-font) no_font="true" ;;
      dark|light) filter="$arg" ;;
    esac
  done
  source "$THEME_LIB/cache.sh"
  ensure_cache
  local name
  name=$(RAND_FILTER="$filter" RAND_GOGH="$GOGH_CACHE" RAND_CUSTOM="$CUSTOM_THEMES" python3 << 'PYEOF'
import os, json, random, sys
sys.path.insert(0, os.path.expanduser('~/.local/share/theme/lib'))
from colors import from_hex, rel_lum, contrast, is_dark, quality_ok
import colorsys

def rgb2hsl(r, g, b):
    h, l, s = colorsys.rgb_to_hls(r/255, g/255, b/255)
    return h*360, s, l

filter_mode = os.environ.get("RAND_FILTER", "")
gogh_path = os.environ["RAND_GOGH"]
custom_path = os.environ.get("RAND_CUSTOM", "")

themes = json.load(open(gogh_path))
if custom_path and os.path.exists(custom_path):
    themes = json.load(open(custom_path)) + themes

candidates = []
for t in themes:
    dark = is_dark(t)
    if filter_mode == "dark" and not dark: continue
    if filter_mode == "light" and dark: continue
    if not quality_ok(t): continue
    candidates.append(t)

if not candidates:
    print("", file=sys.stderr)
    sys.exit(1)

pick = random.choice(candidates)
print(pick["name"])
print(f"\033[2m  ({len(candidates)} quality themes in pool)\033[0m", file=sys.stderr)
PYEOF
  )

  if [[ -n "$name" ]]; then
    source "$THEME_DIR/commands/set.sh"
    cmd_set "$name"
    # Also randomize font unless --no-font
    if [[ -z "$no_font" ]]; then
      source "$THEME_DIR/commands/font.sh"
      local fonts pick
      fonts=$(get_nerd_fonts)
      pick=$(echo "$fonts" | shuf -n1)
      if [[ -n "$pick" ]]; then
        echo -e "  ${DIM}Random font:${RESET} $pick"
        apply_font "$pick"
      fi
    fi
  else
    echo -e "${RED}  No quality themes found${RESET}"
  fi
}
