#!/usr/bin/env bash
# cmd_set — set theme by name (Gogh or custom)

cmd_set() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo -e "${RED}Usage: theme set <theme-name>${RESET}"
    exit 1
  fi
  source "$THEME_LIB/cache.sh"
  ensure_cache
  python3 << PYEOF
import json, sys, os
sys.path.insert(0, os.path.expanduser('~/.local/share/theme/lib'))
from colors import blend

name = """${name}"""
themes = json.load(open("$GOGH_CACHE"))

# Load custom themes
custom = []
custom_path = "$CUSTOM_THEMES"
if os.path.exists(custom_path):
    custom = json.load(open(custom_path))

all_themes = custom + themes

# Exact match (case-insensitive) — custom themes checked first
match = None
for t in all_themes:
    if t["name"].lower() == name.lower():
        match = t
        break

# Partial match
if not match:
    partial = [t for t in all_themes if name.lower() in t["name"].lower()]
    if len(partial) == 1:
        match = partial[0]
    elif len(partial) > 1:
        print(f"\033[33m  Multiple matches for '{name}':\033[0m")
        for t in partial:
            custom_tag = " \033[35m(custom)\033[0m" if t in custom else ""
            print(f"    - {t['name']}{custom_tag}")
        print(f"\n  Be more specific.")
        sys.exit(1)

if not match:
    print(f"\033[31m  Theme '{name}' not found\033[0m")
    from difflib import get_close_matches
    all_names = [t["name"] for t in all_themes]
    similar = get_close_matches(name, all_names, n=5, cutoff=0.4)
    if not similar:
        similar = get_close_matches(name.lower(), [n.lower() for n in all_names], n=5, cutoff=0.3)
        if similar:
            similar = [n for n in all_names if n.lower() in similar]
    if similar:
        print(f"\n  \033[33mDid you mean:\033[0m")
        for s in similar:
            print(f"    - {s}")
    sys.exit(1)

is_custom = match in custom

# Extract colors
def strip(c):
    return c.lstrip('#').lower() if c else ''

bg = strip(match.get('background', ''))
fg = strip(match.get('foreground', ''))
cursor = strip(match.get('cursor', ''))

# color_01-08 = normal colors (black, red, green, yellow, blue, magenta, cyan, white)
# color_09-16 = bright colors
c = {}
for i in range(1, 17):
    c[i] = strip(match.get(f'color_{i:02d}', ''))

# Use extra fields from custom themes if available, otherwise derive via blending
bg_light = strip(match.get('bg_light', '')) or blend(bg, fg, 0.07)
bg_highlight = strip(match.get('bg_highlight', '')) or blend(bg, fg, 0.19)
fg_dim = strip(match.get('fg_dim', '')) or blend(fg, bg, 0.33)
fg_muted = strip(match.get('fg_muted', '')) or blend(fg, bg, 0.55)
border = strip(match.get('border', '')) or blend(bg, fg, 0.28)

source_label = "custom" if is_custom else "Gogh"
palette = f"""# Terminal color palette — single source of truth
# Theme: {match['name']} ({source_label})
# Edit this file, then run: theme sync

# Base colors
bg={bg}
bg_light={bg_light}
bg_highlight={bg_highlight}
fg={fg}
fg_dim={fg_dim}
fg_muted={fg_muted}
border={border}

# Terminal 16 colors
black={c[1]}
bright_black={c[9]}
red={c[2]}
bright_red={c[10]}
green={c[3]}
bright_green={c[11]}
yellow={c[4]}
bright_yellow={c[12]}
blue={c[5]}
bright_blue={c[13]}
magenta={c[6]}
bright_magenta={c[14]}
cyan={c[7]}
bright_cyan={c[15]}
white={c[8]}
bright_white={c[16]}

# Accent
cursor={cursor if cursor else c[5]}
url={c[5]}
"""

# Auto-select accent from chromatic colors (highest saturation + contrast from bg)
import colorsys

def hex_hsl(h):
    r, g, b = int(h[0:2],16)/255, int(h[2:4],16)/255, int(h[4:6],16)/255
    hue, lig, sat = colorsys.rgb_to_hls(r, g, b)
    return sat, lig

# Prefer bright_ variants (softer) and desaturate for calm UI
chromatic = [
    ('bright_blue', c[13]), ('bright_cyan', c[15]), ('bright_green', c[11]),
    ('bright_magenta', c[14]), ('cyan', c[7]), ('blue', c[5]),
    ('green', c[3]), ('magenta', c[6]),
]
bg_l = hex_hsl(bg)[1] if bg else 0.1
scored = []
for name, hx in chromatic:
    if not hx or len(hx) != 6: continue
    s, l = hex_hsl(hx)
    gap = abs(l - bg_l)
    if gap < 0.10: continue
    score = s * 1.5 + gap * 0.5
    scored.append((score, hx, name))
scored.sort(reverse=True)

def desaturate(hex_color, amount=0.3):
    """Mix color with gray to reduce saturation"""
    r,g,b = int(hex_color[0:2],16), int(hex_color[2:4],16), int(hex_color[4:6],16)
    gray = int(r*0.299 + g*0.587 + b*0.114)
    r2 = int(r * (1-amount) + gray * amount)
    g2 = int(g * (1-amount) + gray * amount)
    b2 = int(b * (1-amount) + gray * amount)
    return f"{r2:02x}{g2:02x}{b2:02x}"

accent_raw = scored[0][1] if scored else c[13] or c[5]
accent_val = desaturate(accent_raw, 0.25)

palette += f"accent={accent_val}\n"

# Preserve existing font from palette (Gogh themes don't have font)
existing_font = ""
if os.path.exists("$PALETTE"):
    with open("$PALETTE") as pf:
        for pline in pf:
            if pline.startswith("font="):
                existing_font = pline.strip()
                break

theme_font = match.get("font", "")
font_line = f"font={theme_font}" if theme_font else existing_font

tmp_path = "$PALETTE" + ".tmp"
with open(tmp_path, 'w') as f:
    f.write(palette)
    if font_line:
        f.write(f"\n# Font\n{font_line}\n")
os.replace(tmp_path, "$PALETTE")

source_tag = "\033[35m(custom)\033[0m" if is_custom else "\033[2m(Gogh)\033[0m"
print(f"\033[32m  Theme set: {match['name']}\033[0m {source_tag}")

# Show color preview
colors = ""
for i in range(1, 17):
    hex_c = match.get(f'color_{i:02d}', '#000000')
    r, g, b = int(hex_c[1:3], 16), int(hex_c[3:5], 16), int(hex_c[5:7], 16)
    colors += f"\033[48;2;{r};{g};{b}m  \033[0m"
    if i == 8:
        colors += " "
print(f"  {colors}")
print(f"  \033[2mbg:#{bg} fg:#{fg}\033[0m")
if font_line:
    print(f"  \033[2m{font_line}\033[0m")
PYEOF

  if [[ $? -eq 0 ]]; then
    sync
    source "$THEME_DIR/commands/sync.sh"
    apply_palette
    # Post-fix: re-read accent from palette and patch hyprland colors
    source "$THEME_LIB/palette.sh"
    read_palette
    local _a="${C[accent]:-${C[blue]}}"
    for f in "$HOME/.config/hypr/UserConfigs/aurora-colors.conf" "$HOME/.config/hypr/UserConfigs/monochrome-colors.conf"; do
      [[ -f "$f" ]] && python3 -c "
import re,sys
t=open('$f').read()
t=re.sub(r'(\\\$accent = rgb\()([^)]+)\)',r'\g<1>${_a})',t)
t=re.sub(r'(\\\$accent_secondary = rgb\()([^)]+)\)',r'\g<1>${_a})',t)
open('$f','w').write(t)
"
    done
    hyprctl reload >/dev/null 2>&1
    # If theme had font, apply it too
    source "$THEME_DIR/commands/font.sh"
    local theme_font
    theme_font=$(get_current_font)
    if [[ -n "$theme_font" ]]; then
      echo -e "  ${DIM}Applying font:${RESET} $theme_font"
      apply_font "$theme_font"
    fi
  fi
}
