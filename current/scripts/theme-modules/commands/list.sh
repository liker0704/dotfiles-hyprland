#!/usr/bin/env bash
# cmd_list — list all themes with filtering

cmd_list() {
  local filter="" good=""
  for arg in "$@"; do
    case "$arg" in
      dark|light) filter="$arg" ;;
      --good) good="true" ;;
    esac
  done
  source "$THEME_LIB/cache.sh"
  ensure_cache
  python3 << PYEOF
import json, sys, os
sys.path.insert(0, os.path.expanduser('~/.local/share/theme/lib'))
from colors import luminance, is_dark, from_hex, rel_lum, contrast, quality_ok
import colorsys

filter_mode = "${filter}".lower()
good = "${good}" == "true"
themes = json.load(open("$GOGH_CACHE"))
custom = []
custom_path = "$CUSTOM_THEMES"
if os.path.exists(custom_path):
    custom = json.load(open(custom_path))
shown = 0

if custom:
    for t in custom:
        dark = is_dark(t)
        if filter_mode == "dark" and not dark: continue
        if filter_mode == "light" and dark: continue
        if good and not quality_ok(t): continue
        bg = t.get('background', '')
        tag = "\033[2mdark\033[0m" if dark else "\033[33mlight\033[0m"
        print(f'    \033[35m*\033[0m {t["name"]}  [{tag}]  \033[2m{bg}\033[0m')
        shown += 1

for i, t in enumerate(themes, 1):
    dark = is_dark(t)
    if filter_mode == "dark" and not dark: continue
    if filter_mode == "light" and dark: continue
    if good and not quality_ok(t): continue
    bg = t.get('background', '')
    tag = "\033[2mdark\033[0m" if dark else "\033[33mlight\033[0m"
    print(f'  {i:3d}. {t["name"]}  [{tag}]  \033[2m{bg}\033[0m')
    shown += 1

q_label = ", quality" if good else ""
label = f" ({filter_mode}{q_label})" if filter_mode in ("dark", "light") or good else ""
print(f'\n  Total: {shown} themes{label}')
PYEOF
}
