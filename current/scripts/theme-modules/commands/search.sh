#!/usr/bin/env bash
# cmd_search — search themes with fuzzy matching and color preview

cmd_search() {
  # Parse --dark/--light/--good flags
  local filter="" query="" good=""
  for arg in "$@"; do
    case "$arg" in
      --dark)  filter="dark" ;;
      --light) filter="light" ;;
      --good)  good="true" ;;
      *)       query="$arg" ;;
    esac
  done
  if [[ -z "$query" && -z "$filter" ]]; then
    echo -e "${RED}Usage: theme search <query> [--dark|--light]${RESET}"
    exit 1
  fi
  source "$THEME_LIB/cache.sh"
  ensure_cache
  python3 << PYEOF
import json, sys, os
sys.path.insert(0, os.path.expanduser('~/.local/share/theme/lib'))
from colors import luminance, is_dark, from_hex, rel_lum, contrast, quality_ok
import colorsys

query = """${query}""".lower()
filter_mode = "${filter}"
good = "${good}" == "true"
themes = json.load(open("$GOGH_CACHE"))

# Load custom themes
custom = []
custom_path = "$CUSTOM_THEMES"
if os.path.exists(custom_path):
    custom = json.load(open(custom_path))

all_themes = [(t, True) for t in custom] + [(t, False) for t in themes]
matches = []

for t, is_custom in all_themes:
    # Apply dark/light filter
    dark = is_dark(t)
    if filter_mode == "dark" and not dark: continue
    if filter_mode == "light" and dark: continue
    if good and not quality_ok(t): continue
    # Apply name filter (if query given)
    if query and query not in t["name"].lower(): continue
    matches.append((t, is_custom))

if not matches:
    label = query or filter_mode
    print(f"\033[31m  No themes matching '{label}'\033[0m")
    if query:
        from difflib import get_close_matches
        all_names = [t["name"] for t in custom] + [t["name"] for t in themes]
        similar = get_close_matches(query, [n.lower() for n in all_names], n=5, cutoff=0.4)
        if similar:
            print(f"\n  \033[33mDid you mean:\033[0m")
            for s in similar:
                for t in custom + themes:
                    if t["name"].lower() == s:
                        print(f"    - {t['name']}")
                        break
    sys.exit(1)

print(f"\n  Found {len(matches)} theme(s):\n")
for t, is_custom in matches:
    name = t["name"]
    bg = t.get("background", "")
    fg = t.get("foreground", "")
    dark = is_dark(t)
    tag = "\033[2mdark\033[0m" if dark else "\033[33mlight\033[0m"
    prefix = "\033[35m*\033[0m " if is_custom else "  "
    # Highlight matching part
    highlighted = name
    if query:
        idx = name.lower().find(query)
        if idx >= 0:
            highlighted = name[:idx] + f"\033[1;33m{name[idx:idx+len(query)]}\033[0m" + name[idx+len(query):]
    # Show color swatches
    colors = ""
    for i in range(1, 9):
        c = t.get(f"color_{i:02d}", "")
        if c:
            r, g, b = int(c[1:3], 16), int(c[3:5], 16), int(c[5:7], 16)
            colors += f"\033[48;2;{r};{g};{b}m  \033[0m"
    print(f"{prefix}{highlighted}  [{tag}]  {colors}  \033[2mbg:{bg} fg:{fg}\033[0m")

print(f"\n  \033[2mUse: theme set \"<name>\" to apply\033[0m")
PYEOF
}
