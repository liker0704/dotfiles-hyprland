# Alacritty terminal (auto-reloads on file change)

local ALACRITTY_CONF="$HOME/.config/alacritty/alacritty.toml"
if [[ -f "$ALACRITTY_CONF" ]]; then
  # Convert hex to 0x format for alacritty
  local _h="0x"
  sed -i \
    -e 's|^\(background = \)"0x[^"]*"|\1"'"${_h}${C[bg]}"'"|' \
    -e 's|^\(foreground = \)"0x[^"]*"|\1"'"${_h}${C[fg]}"'"|' \
    "$ALACRITTY_CONF"

  # Normal colors
  local _section=""
  python3 -c "
import re, sys

colors = {
    'normal': {
        'black': '${C[black]}', 'red': '${C[red]}', 'green': '${C[green]}',
        'yellow': '${C[yellow]}', 'blue': '${C[blue]}', 'magenta': '${C[magenta]}',
        'cyan': '${C[cyan]}', 'white': '${C[white]}'
    },
    'bright': {
        'black': '${C[bright_black]}', 'red': '${C[bright_red]}', 'green': '${C[bright_green]}',
        'yellow': '${C[bright_yellow]}', 'blue': '${C[bright_blue]}', 'magenta': '${C[bright_magenta]}',
        'cyan': '${C[bright_cyan]}', 'white': '${C[bright_white]}'
    },
    'cursor': {
        'cursor': '${C[cursor]}', 'text': '${C[bg]}'
    },
    'selection': {
        'background': '${C[bright_black]}', 'text': '${C[fg]}'
    }
}

with open('$ALACRITTY_CONF') as f:
    lines = f.readlines()

section = ''
out = []
for line in lines:
    m = re.match(r'^\[colors\.(\w+)\]', line)
    if m:
        section = m.group(1)
        out.append(line)
        continue
    if section in colors:
        km = re.match(r'^(\w+)\s*=\s*\"0x', line)
        if km and km.group(1) in colors[section]:
            key = km.group(1)
            out.append(f'{key} = \"0x{colors[section][key]}\"\n')
            continue
    out.append(line)

with open('$ALACRITTY_CONF', 'w') as f:
    f.writelines(out)
"
  echo -e "    ${GREEN}alacritty${RESET}"
fi
