#!/usr/bin/env bash
# cmd_import — import theme from file, URL, or clipboard

cmd_import() {
  local src="$1" label="clipboard"
  local tmpfile=""

  if [[ -z "$src" ]]; then
    # No arg — read from clipboard
    if ! command -v wl-paste &>/dev/null; then
      echo -e "${RED}wl-paste not found (install wl-clipboard)${RESET}"
      exit 1
    fi
    tmpfile=$(mktemp)
    wl-paste --no-newline > "$tmpfile" 2>/dev/null
    if [[ ! -s "$tmpfile" ]]; then
      rm -f "$tmpfile"
      echo -e "${RED}Clipboard is empty${RESET}"
      exit 1
    fi
    src="$tmpfile"
    echo -e "  ${DIM}Reading from clipboard...${RESET}"
  elif [[ "$src" == http* ]]; then
    label="$(basename "$src")"
    tmpfile=$(mktemp)
    echo -e "  ${DIM}Downloading...${RESET}"
    curl -sL "$src" -o "$tmpfile" || { echo -e "${RED}Download failed${RESET}"; exit 1; }
    src="$tmpfile"
  else
    label="$(basename "$src")"
    [[ ! -f "$src" ]] && { echo -e "${RED}File not found: $src${RESET}"; exit 1; }
  fi

  # Auto-detect: Xresources or kitty
  local is_xres=false
  if grep -qE '^\*\.?color[0-9]+:' "$src" 2>/dev/null; then
    is_xres=true
  fi

  local bg fg cursor sel_bg
  local c0 c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14 c15

  if $is_xres; then
    # Xresources: *.color0: #1a1b26  or  *color0: #1a1b26
    xget() { grep -iE '^\*\.?'"$1"':' "$src" | head -1 | grep -oP '#?\K[0-9a-fA-F]{6}' | head -1; }
    bg=$(xget "background"); fg=$(xget "foreground"); cursor=$(xget "cursorColor")
    c0=$(xget "color0"); c1=$(xget "color1"); c2=$(xget "color2"); c3=$(xget "color3")
    c4=$(xget "color4"); c5=$(xget "color5"); c6=$(xget "color6"); c7=$(xget "color7")
    c8=$(xget "color8"); c9=$(xget "color9"); c10=$(xget "color10"); c11=$(xget "color11")
    c12=$(xget "color12"); c13=$(xget "color13"); c14=$(xget "color14"); c15=$(xget "color15")
  else
    # Kitty: color0 #1a1b26
    get() { grep -iE "^$1\b" "$src" | head -1 | grep -oP '#?\K[0-9a-fA-F]{6}' | head -1; }
    bg=$(get "background"); fg=$(get "foreground"); cursor=$(get "cursor[^_]"); sel_bg=$(get "selection_background")
    c0=$(get "color0[^0-9]"); c1=$(get "color1[^0-9]"); c2=$(get "color2[^0-9]"); c3=$(get "color3[^0-9]")
    c4=$(get "color4[^0-9]"); c5=$(get "color5[^0-9]"); c6=$(get "color6[^0-9]"); c7=$(get "color7[^0-9]")
    c8=$(get "color8[^0-9]"); c9=$(get "color9[^0-9]"); c10=$(get "color10"); c11=$(get "color11")
    c12=$(get "color12"); c13=$(get "color13"); c14=$(get "color14"); c15=$(get "color15")
  fi

  [[ -z "$bg" || -z "$fg" ]] && { echo -e "${RED}Can't parse colors. Supported: kitty .conf, Xresources${RESET}"; rm -f "$tmpfile"; exit 1; }

  local fmt="kitty"; $is_xres && fmt="Xresources"

  cat > "$PALETTE" << EOF
# Terminal color palette — single source of truth
# Imported from: $label ($fmt)
# Edit this file, then run: theme sync

# Base colors
bg=$bg
bg_light=${c8:-$bg}
bg_highlight=${sel_bg:-${c8:-$bg}}
fg=$fg
fg_dim=${c7:-$fg}
fg_muted=${c8:-${c7:-71717a}}
border=${c8:-${c8:-$bg}}

# Terminal 16 colors
black=${c0:-$bg}
bright_black=${c8:-$bg}
red=${c1:-f7768e}
bright_red=${c9:-${c1:-f7768e}}
green=${c2:-9ece6a}
bright_green=${c10:-${c2:-9ece6a}}
yellow=${c3:-e0af68}
bright_yellow=${c11:-${c3:-e0af68}}
blue=${c4:-7aa2f7}
bright_blue=${c12:-${c4:-7aa2f7}}
magenta=${c5:-bb9af7}
bright_magenta=${c13:-${c5:-bb9af7}}
cyan=${c6:-7dcfff}
bright_cyan=${c14:-${c6:-7dcfff}}
white=${c7:-a1a1aa}
bright_white=${c15:-$fg}

# Accent
cursor=${cursor:-${c4:-7aa2f7}}
url=${c4:-7aa2f7}
EOF

  [[ -n "$tmpfile" ]] && rm -f "$tmpfile"
  echo -e "  ${GREEN}Imported${RESET} ${DIM}($fmt)${RESET}"
  source "$THEME_DIR/commands/sync.sh"
  apply_palette
}
