#!/usr/bin/env bash
# cmd_fav — manage favorite themes

cmd_fav() {
  local sub="${1:-}"
  case "$sub" in
    add)
      local name="${2:-}"
      if [[ -z "$name" ]]; then
        # Add current theme (strip source tag like "(Gogh)" or "(custom)")
        name=$(grep -oP '# Theme: \K.*' "$PALETTE" 2>/dev/null | sed 's/ (Gogh)$//;s/ (custom)$//' || echo "")
        [[ -z "$name" ]] && { echo -e "${RED}No theme set${RESET}"; exit 1; }
      fi
      touch "$FAVORITES"
      if grep -qxF "$name" "$FAVORITES" 2>/dev/null; then
        echo -e "${YELLOW}Already in favorites:${RESET} $name"
      else
        echo "$name" >> "$FAVORITES"
        echo -e "${GREEN}Added:${RESET} $name"
      fi
      ;;
    rm|remove)
      local name="${2:-}"
      [[ -z "$name" ]] && { echo -e "${RED}Usage: theme fav rm <name>${RESET}"; exit 1; }
      if [[ ! -f "$FAVORITES" ]] || ! grep -qxF "$name" "$FAVORITES" 2>/dev/null; then
        echo -e "${RED}Not in favorites:${RESET} $name"
        exit 1
      fi
      local tmp; tmp=$(grep -vxF "$name" "$FAVORITES")
      echo "$tmp" > "$FAVORITES"
      echo -e "${GREEN}Removed:${RESET} $name"
      ;;
    next|prev)
      if [[ ! -f "$FAVORITES" ]] || [[ ! -s "$FAVORITES" ]]; then
        echo -e "${RED}No favorites. Use: theme fav add${RESET}"; exit 1
      fi
      local current
      current=$(grep -oP '# Theme: \K.*' "$PALETTE" 2>/dev/null | sed 's/ (Gogh)$//;s/ (custom)$//' || echo "")
      local -a favs=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && favs+=("$line")
      done < "$FAVORITES"
      local count=${#favs[@]}
      local idx=-1
      for i in "${!favs[@]}"; do
        [[ "${favs[$i]}" == "$current" ]] && idx=$i
      done
      if [[ "$sub" == "next" ]]; then
        idx=$(( (idx + 1) % count ))
      else
        idx=$(( (idx - 1 + count) % count ))
      fi
      echo -e "  ${BOLD}→ ${favs[$idx]}${RESET}"
      source "$THEME_DIR/commands/set.sh"
      cmd_set "${favs[$idx]}"
      ;;
    [0-9]*)
      if [[ ! -f "$FAVORITES" ]] || [[ ! -s "$FAVORITES" ]]; then
        echo -e "${RED}No favorites${RESET}"; exit 1
      fi
      local n=$((sub))
      local line
      line=$(sed -n "${n}p" "$FAVORITES")
      if [[ -z "$line" ]]; then
        echo -e "${RED}No favorite #${n}${RESET}"; exit 1
      fi
      source "$THEME_DIR/commands/set.sh"
      cmd_set "$line"
      ;;
    "")
      # List favorites with color swatches
      if [[ ! -f "$FAVORITES" ]] || [[ ! -s "$FAVORITES" ]]; then
        echo -e "  ${DIM}No favorites. Use: theme fav add [name]${RESET}"
        return
      fi
      source "$THEME_LIB/cache.sh"
      ensure_cache
      local current
      current=$(grep -oP '# Theme: \K.*' "$PALETTE" 2>/dev/null | sed 's/ (Gogh)$//;s/ (custom)$//' || echo "")
      python3 << PYEOF
import json, os, sys
sys.path.insert(0, os.path.expanduser('~/.local/share/theme/lib'))

current = """${current}"""
favs = [l.strip() for l in open("$FAVORITES") if l.strip()]

# Load all themes
themes = {}
gogh = json.load(open("$GOGH_CACHE"))
for t in gogh:
    themes[t["name"]] = t
custom_path = "$CUSTOM_THEMES"
if os.path.exists(custom_path):
    for t in json.load(open(custom_path)):
        themes[t["name"]] = t

def swatch(t):
    s = ""
    # Try color_01-08 (Gogh), fallback to palette keys
    keys = [f"color_{i:02d}" for i in range(1, 9)]
    for k in keys:
        c = t.get(k, "")
        if not c:
            continue
        c = c.lstrip('#')
        if len(c) != 6:
            continue
        r, g, b = int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16)
        s += f"\033[48;2;{r};{g};{b}m  \033[0m"
    return s

print()
for i, name in enumerate(favs, 1):
    t = themes.get(name)
    if t:
        sw = swatch(t)
        bg = t.get("background", "")
    else:
        sw = ""
        bg = ""
    if name == current:
        print(f"  \033[32m{i})\033[0m \033[1m{name}\033[0m  {sw}  \033[32m←\033[0m")
    else:
        print(f"  \033[2m{i})\033[0m {name}  {sw}  \033[2m{bg}\033[0m")
print()
PYEOF
      ;;
    *)
      echo -e "${RED}Usage: theme fav [add|rm|next|prev|N]${RESET}"
      exit 1
      ;;
  esac
}
