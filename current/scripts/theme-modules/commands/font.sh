#!/usr/bin/env bash
# Font management commands

# Get installed monospace Nerd Fonts
get_nerd_fonts() {
  # Get non-Mono variants first, then Mono-only fonts (like Iosevka)
  local non_mono mono_only
  non_mono=$(fc-list :spacing=100 family | sed 's/,.*//' | grep "Nerd Font" | grep -v "Nerd Font Mono" | grep -v "MonoNL\|NerdFont" | sort -u)
  mono_only=$(fc-list :spacing=100 family | sed 's/,.*//' | grep "Nerd Font Mono" | grep -v "MonoNL\|NerdFont" | sort -u | while read -r f; do
    base="${f% Mono}"
    echo "$non_mono" | grep -qF "$base" || echo "$f"
  done)
  { echo "$non_mono"; echo "$mono_only"; } | grep -v '^$' | sort -u
}

# Get current font from palette.conf
get_current_font() {
  if [[ -f "$PALETTE" ]]; then
    grep '^font=' "$PALETTE" 2>/dev/null | cut -d= -f2-
  fi
}

# Apply font to all configs
apply_font() {
  local FONT="$1"
  [[ -z "$FONT" ]] && return 1

  # 1. Update palette.conf
  if grep -q '^font=' "$PALETTE" 2>/dev/null; then
    sed -i "s/^font=.*/font=$FONT/" "$PALETTE"
  else
    echo "" >> "$PALETTE"
    echo "# Font" >> "$PALETTE"
    echo "font=$FONT" >> "$PALETTE"
  fi

  # 2. Kitty
  local KITTY_CONF="$HOME/.config/kitty/kitty.conf"
  if [[ -f "$KITTY_CONF" ]]; then
    sed -i "s/^font_family .*/font_family $FONT/" "$KITTY_CONF"
    echo -e "    ${GREEN}kitty${RESET} → $FONT"
  fi

  # 3. Alacritty
  local ALACRITTY_CONF="$HOME/.config/alacritty/alacritty.toml"
  if [[ -f "$ALACRITTY_CONF" ]]; then
    sed -i 's/^family = ".*"/family = "'"$FONT"'"/' "$ALACRITTY_CONF"
    echo -e "    ${GREEN}alacritty${RESET}"
  fi

  # 4. Waybar — update existing CSS if present (heredoc regenerated on next theme sync)
  local WAYBAR_CSS="$HOME/.config/waybar/style-minimal.css"
  if [[ -f "$WAYBAR_CSS" ]]; then
    sed -i 's/font-family: "[^"]*Nerd Font[^"]*"/font-family: "'"$FONT"'"/' "$WAYBAR_CSS"
    echo -e "    ${GREEN}waybar${RESET}"
  fi

  # 5. Rofi
  local ROFI_FONTS="$HOME/.config/rofi/0-shared-fonts.rasi"
  if [[ -f "$ROFI_FONTS" ]]; then
    sed -i 's/"[^"]*Nerd Font[^"]*SemiBold/"'"$FONT"' SemiBold/g' "$ROFI_FONTS"
    echo -e "    ${GREEN}rofi${RESET}"
  fi

  # 6. SwayNC
  local SWAYNC_STYLE="$HOME/.config/swaync/style.css"
  if [[ -f "$SWAYNC_STYLE" ]]; then
    sed -i 's/font-family: "[^"]*Nerd Font[^"]*"/font-family: "'"$FONT"'"/' "$SWAYNC_STYLE"
    echo -e "    ${GREEN}swaync${RESET}"
  fi

  # 7. Hyprlock (clock line only — ExtraBold)
  for hl in "$HOME/.config/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock-2k.conf"; do
    if [[ -f "$hl" ]]; then
      sed -i 's/font_family = .*ExtraBold/font_family = '"$FONT"' ExtraBold/' "$hl"
    fi
  done
  echo -e "    ${GREEN}hyprlock${RESET}"

  # 8. Zen Browser (monospace font in user.js)
  local ZEN_USERJS="$HOME/.var/app/app.zen_browser.zen/.zen/21bfpd4i.Default (release)/user.js"
  if [[ -f "$ZEN_USERJS" ]]; then
    if grep -q 'font\.name\.monospace\.x-western' "$ZEN_USERJS"; then
      sed -i 's/user_pref("font\.name\.monospace\.x-western".*/user_pref("font.name.monospace.x-western", "'"$FONT"'");/' "$ZEN_USERJS"
    else
      echo "user_pref(\"font.name.monospace.x-western\", \"$FONT\");" >> "$ZEN_USERJS"
    fi
    echo -e "    ${GREEN}zen${RESET} (new tabs)"
  fi

  # Reload
  if pgrep -x kitty &>/dev/null; then
    kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null
  fi
  if pgrep -x swaync &>/dev/null; then
    swaync-client -rs &>/dev/null
  fi
  if pgrep -x waybar &>/dev/null; then
    pkill waybar; sleep 0.3; waybar &>/dev/null & disown
  fi
}

# Font commands
cmd_font() {
  local subcmd="${1:-}"
  local arg="${2:-}"

  case "$subcmd" in
    set)
      [[ -z "$arg" ]] && { echo -e "${RED}Usage: theme font set <name>${RESET}"; exit 1; }
      local fonts match
      fonts=$(get_nerd_fonts)

      # Exact match (case-insensitive)
      match=$(echo "$fonts" | grep -i "^${arg}$" | head -1)

      # Partial match
      if [[ -z "$match" ]]; then
        local partial
        partial=$(echo "$fonts" | grep -i "$arg")
        local count
        count=$(echo "$partial" | grep -c .)
        if [[ "$count" -eq 1 ]]; then
          match="$partial"
        elif [[ "$count" -gt 1 ]]; then
          echo -e "  ${YELLOW}Multiple matches for '$arg':${RESET}"
          echo "$partial" | while read -r f; do echo "    - $f"; done
          echo -e "\n  Be more specific."
          return 1
        fi
      fi

      if [[ -z "$match" ]]; then
        echo -e "  ${RED}Font '$arg' not found${RESET}"
        echo -e "\n  ${DIM}Installed Nerd Fonts:${RESET}"
        get_nerd_fonts | while read -r f; do echo "    $f"; done
        return 1
      fi

      echo -e "  ${BOLD}Setting font:${RESET} $match"
      apply_font "$match"
      echo -e "  ${BOLD}Done!${RESET}"
      ;;

    random)
      local fonts current
      fonts=$(get_nerd_fonts)
      current=$(get_current_font)
      local pick
      pick=$(echo "$fonts" | grep -v "^${current}$" | shuf -n1)
      if [[ -z "$pick" ]]; then
        echo -e "  ${RED}No other fonts available${RESET}"
        return 1
      fi
      echo -e "  ${BOLD}Random font:${RESET} $pick"
      apply_font "$pick"
      echo -e "  ${BOLD}Done!${RESET}"
      ;;

    list|"")
      local fonts current
      fonts=$(get_nerd_fonts)
      current=$(get_current_font)
      [[ -z "$current" ]] && current="JetBrainsMono Nerd Font"
      echo ""
      echo -e "  ${BOLD}Current font:${RESET} $current"
      echo ""
      echo -e "  ${DIM}Installed Nerd Fonts:${RESET}"
      echo "$fonts" | while read -r f; do
        if [[ "$f" == "$current" ]]; then
          echo -e "    ${GREEN}*${RESET} $f  ${DIM}(current)${RESET}"
        else
          echo "      $f"
        fi
      done
      echo ""
      ;;

    *)
      echo -e "${RED}Usage: theme font [set <name>|random|list]${RESET}"
      exit 1
      ;;
  esac
}
