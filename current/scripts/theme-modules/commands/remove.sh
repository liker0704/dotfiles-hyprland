#!/usr/bin/env bash
# cmd_remove — remove custom theme

cmd_remove() {
  local name="$1"
  [[ -z "$name" ]] && { echo -e "${RED}Usage: theme remove <name>${RESET}"; exit 1; }
  [[ ! -f "$CUSTOM_THEMES" ]] && { echo -e "${RED}No custom themes${RESET}"; exit 1; }

  python3 << PYEOF
import json, sys, os
sys.path.insert(0, os.path.expanduser('~/.local/share/theme/lib'))

name = """${name}"""
custom_path = "$CUSTOM_THEMES"

with open(custom_path) as f:
    themes = json.load(f)

original = len(themes)
themes = [t for t in themes if t["name"].lower() != name.lower()]

if len(themes) == original:
    print(f"\033[31m  Theme '{name}' not found in custom themes\033[0m")
    if themes:
        print(f"\n  Custom themes:")
        for t in themes:
            print(f"    - {t['name']}")
    sys.exit(1)

with open(custom_path, 'w') as f:
    json.dump(themes, f, indent=2)

print(f"\033[32m  Theme '{name}' removed\033[0m ({len(themes)} custom themes)")
PYEOF
}
