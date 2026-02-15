#!/usr/bin/env bash
# cmd_generate — generate random palette using HSLuv

cmd_generate() {
  local mode="dark" wild="" seed="" no_font=""
  for arg in "$@"; do
    case "$arg" in
      dark|light) mode="$arg" ;;
      --wild) wild="true" ;;
      --seed=*) seed="${arg#--seed=}" ;;
      --no-font) no_font="true" ;;
    esac
  done
  echo -e "  ${DIM}Generating (HSLuv)...${RESET}"
  if [[ ! -x "$VENV_PY" ]]; then
    echo -e "  ${DIM}Installing hsluv...${RESET}"
    python3 -m venv "$HOME/.local/share/theme-venv"
    "$VENV_PY" -m pip install -q hsluv
  fi
  GEN_MODE="$mode" GEN_WILD="$wild" GEN_SEED="$seed" GEN_PALETTE="$PALETTE" "$VENV_PY" << 'PYEOF'
import os, random, hsluv, sys
sys.path.insert(0, os.path.expanduser('~/.local/share/theme/lib'))
from colors import from_hex, to_hex_rgb, blend, rel_lum, contrast

def to_hex_hsluv(h, s, l):
    """HSLuv → hex (no #). h=0-360, s=0-100, l=0-100"""
    return hsluv.hsluv_to_hex([h % 360, max(0,min(100,s)), max(0,min(100,l))])[1:]

def hex_to_hsluv(h):
    return hsluv.hex_to_hsluv('#' + h.lstrip('#'))

def tint(target_h, base_h, amount=15):
    diff = ((base_h - target_h + 180) % 360) - 180
    return (target_h + max(-amount, min(amount, diff))) % 360

mode = os.environ.get("GEN_MODE", "dark")
wild = os.environ.get("GEN_WILD") == "true"
seed_hex = os.environ.get("GEN_SEED", "").lstrip('#')
palette_path = os.environ["GEN_PALETTE"]

# Base hue
if seed_hex and len(seed_hex) == 6:
    base_h, _, _ = hex_to_hsluv(seed_hex)
else:
    base_h = random.uniform(0, 360)

# BG / FG  (HSLuv L: 0-100)
is_light = mode == "light"
bg_l = random.uniform(92, 97) if is_light else random.uniform(5, 12)
fg_l = random.uniform(15, 25) if is_light else random.uniform(80, 92)
bg_s = random.uniform(8, 30)
fg_s = random.uniform(5, 18)
bg = to_hex_hsluv(base_h, bg_s, bg_l)
fg = to_hex_hsluv(base_h, fg_s, fg_l)

# Ensure contrast >= 4.5:1
for _ in range(40):
    if contrast(bg, fg) >= 4.5: break
    if is_light:
        bg_l = min(bg_l + 1.5, 99); fg_l = max(fg_l - 1.5, 3)
    else:
        bg_l = max(bg_l - 1, 1); fg_l = min(fg_l + 1.5, 98)
    bg = to_hex_hsluv(base_h, bg_s, bg_l)
    fg = to_hex_hsluv(base_h, fg_s, fg_l)

c = {}
if wild:
    # Normal 0-7: monochrome ramp of base hue
    ramp = [5, 10, 18, 28, 40, 55, 72, 90]
    if is_light: ramp = [100 - x for x in ramp]
    for i in range(8):
        h = base_h + random.uniform(-3, 3)
        s = random.uniform(8, 30)
        l = ramp[i] + random.uniform(-2, 2)
        c[i] = to_hex_hsluv(h, s, max(2, min(98, l)))
    # Bright 8-15: golden angle spread accents
    start = random.uniform(0, 360)
    l_center = 45 if is_light else 65
    for i in range(8):
        h = (start + i * 137.508) % 360
        s = random.uniform(55, 90)
        l = l_center + random.uniform(-6, 6)
        c[8+i] = to_hex_hsluv(h, s, max(25, min(80, l)))
else:
    # Traditional ANSI zones — all at same perceptual lightness
    # HSLuv hues for ANSI colors (perceptually spaced)
    normal_l = random.uniform(55, 68) if not is_light else random.uniform(38, 50)
    bright_l = normal_l + (10 if not is_light else -10)
    normal_s = random.uniform(70, 95)
    bright_s = min(100, normal_s + random.uniform(3, 10))

    #           hue   (ANSI standard zones)
    zones = [
        base_h,   # 0 black  (handled separately)
        12,       # 1 red
        127,      # 2 green
        75,       # 3 yellow
        265,      # 4 blue
        308,      # 5 magenta
        205,      # 6 cyan
        base_h,   # 7 white  (handled separately)
    ]

    for i, zh in enumerate(zones):
        if i == 0:
            # black: very dark/light, low saturation
            bl = random.uniform(12, 20) if not is_light else random.uniform(82, 90)
            c[i] = to_hex_hsluv(base_h + random.uniform(-5,5), random.uniform(5, 20), bl)
        elif i == 7:
            # white: opposite of black
            wl = random.uniform(68, 78) if not is_light else random.uniform(25, 35)
            c[i] = to_hex_hsluv(base_h + random.uniform(-5,5), random.uniform(5, 18), wl)
        else:
            # Color: tinted toward base hue, perceptually uniform lightness
            h = tint(zh, base_h, 15) + random.uniform(-8, 8)
            c[i] = to_hex_hsluv(h, normal_s, normal_l + random.uniform(-3, 3))

    # Bright variants: same hue, brighter, more saturated
    for i in range(8):
        h_orig, s_orig, l_orig = hex_to_hsluv(c[i])
        if i == 0:
            c[8] = to_hex_hsluv(h_orig, min(100, s_orig + 5), l_orig + (15 if not is_light else -12))
        elif i == 7:
            c[15] = to_hex_hsluv(h_orig, min(100, s_orig + 3), l_orig + (12 if not is_light else -12))
        else:
            c[8+i] = to_hex_hsluv(h_orig, bright_s, bright_l + random.uniform(-3, 3))

# Use seed color as cursor if provided
cursor = seed_hex if (seed_hex and len(seed_hex) == 6) else c[4]

# Derived colors (blend in RGB space)
bg_light = blend(bg, fg, 0.07)
bg_highlight = blend(bg, fg, 0.19)
fg_dim = blend(fg, bg, 0.33)
fg_muted = blend(fg, bg, 0.55)
border_c = blend(bg, fg, 0.28)

# Write palette
names = ['black','red','green','yellow','blue','magenta','cyan','white']
label = "wild" if wild else "generated"
lines = [
    "# Terminal color palette — single source of truth",
    f"# Theme: Random ({label}, hue={base_h:.0f})",
    "# Edit this file, then run: theme sync",
    "", "# Base colors",
    f"bg={bg}", f"bg_light={bg_light}", f"bg_highlight={bg_highlight}",
    f"fg={fg}", f"fg_dim={fg_dim}", f"fg_muted={fg_muted}", f"border={border_c}",
    "", "# Terminal 16 colors",
]
for i in range(8):
    lines.append(f"{names[i]}={c[i]}")
    lines.append(f"bright_{names[i]}={c[8+i]}")
lines += ["", "# Accent", f"cursor={cursor}", f"url={c[4]}"]

tmp_path = palette_path + ".tmp"
with open(tmp_path, 'w') as f:
    f.write('\n'.join(lines) + '\n')
os.replace(tmp_path, palette_path)

# Preview
print(f"  ", end="")
for i in range(16):
    r, g, b = from_hex(c[i])
    print(f"\033[48;2;{r};{g};{b}m  \033[0m", end="")
    if i == 7: print(" ", end="")
print()
cr = contrast(bg, fg)
print(f"  \033[2mbg:#{bg} fg:#{fg} contrast:{cr:.1f}:1 hue:{base_h:.0f}\033[0m")
PYEOF

  if [[ $? -eq 0 ]]; then
    source "$THEME_DIR/commands/sync.sh"
    apply_palette
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
  fi
}
