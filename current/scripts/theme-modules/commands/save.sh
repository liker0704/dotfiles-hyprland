#!/usr/bin/env bash
# cmd_save — save current palette as custom theme

cmd_save() {
  local name="$1"
  [[ -z "$name" ]] && { echo -e "${RED}Usage: theme save <name>${RESET}"; exit 1; }
  [[ ! -f "$PALETTE" ]] && { echo -e "${RED}No palette set${RESET}"; exit 1; }

  python3 << PYEOF
import json, os, sys
sys.path.insert(0, os.path.expanduser('~/.local/share/theme/lib'))

name = """${name}"""
palette_path = "$PALETTE"
custom_path = "$CUSTOM_THEMES"

# Read palette
C = {}
with open(palette_path) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'): continue
        if '=' in line:
            k, v = line.split('=', 1)
            C[k.strip()] = v.strip()

# Build Gogh-format theme + extra palette fields
theme = {
    "name": name,
    "background": "#" + C.get("bg", "000000"),
    "foreground": "#" + C.get("fg", "ffffff"),
    "cursor": "#" + C.get("cursor", C.get("blue", "7aa2f7")),
    "color_01": "#" + C.get("black", "000000"),
    "color_02": "#" + C.get("red", "ff0000"),
    "color_03": "#" + C.get("green", "00ff00"),
    "color_04": "#" + C.get("yellow", "ffff00"),
    "color_05": "#" + C.get("blue", "0000ff"),
    "color_06": "#" + C.get("magenta", "ff00ff"),
    "color_07": "#" + C.get("cyan", "00ffff"),
    "color_08": "#" + C.get("white", "aaaaaa"),
    "color_09": "#" + C.get("bright_black", "555555"),
    "color_10": "#" + C.get("bright_red", "ff0000"),
    "color_11": "#" + C.get("bright_green", "00ff00"),
    "color_12": "#" + C.get("bright_yellow", "ffff00"),
    "color_13": "#" + C.get("bright_blue", "0000ff"),
    "color_14": "#" + C.get("bright_magenta", "ff00ff"),
    "color_15": "#" + C.get("bright_cyan", "00ffff"),
    "color_16": "#" + C.get("bright_white", "ffffff"),
    # Extra fields (not in Gogh, used for precise palette restoration)
    "bg_light": "#" + C.get("bg_light", ""),
    "bg_highlight": "#" + C.get("bg_highlight", ""),
    "fg_dim": "#" + C.get("fg_dim", ""),
    "fg_muted": "#" + C.get("fg_muted", ""),
    "border": "#" + C.get("border", ""),
}
# Add font if present in palette
font = C.get("font", "")
if font:
    theme["font"] = font
# Remove empty extra fields
theme = {k: v for k, v in theme.items() if v != "#"}

# Load existing custom themes
themes = []
if os.path.exists(custom_path):
    with open(custom_path) as f:
        themes = json.load(f)

# Replace if name exists, otherwise append
replaced = False
for i, t in enumerate(themes):
    if t["name"].lower() == name.lower():
        themes[i] = theme
        replaced = True
        break
if not replaced:
    themes.append(theme)

with open(custom_path, 'w') as f:
    json.dump(themes, f, indent=2)

action = "updated" if replaced else "saved"
print(f"\033[32m  Theme '{name}' {action}\033[0m ({len(themes)} custom themes)")
PYEOF
}
