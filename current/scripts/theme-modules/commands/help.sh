# Help and default command

# --- Help ---
cmd_help() {
  echo ""
  echo -e "  ${BOLD}Commands:${RESET}"
  echo ""
  echo -e "    theme set ${DIM}<name>${RESET}              set theme by name (Gogh + custom)"
  echo -e "    theme search ${DIM}<q>${RESET} ${DIM}[--dark|--light|--good]${RESET}"
  echo -e "                                 search themes (fuzzy + color preview)"
  echo -e "    theme list ${DIM}[dark|light]${RESET} ${DIM}[--good]${RESET}"
  echo -e "                                 list all themes (or filtered)"
  echo -e "    theme dark/light ${DIM}[query]${RESET}     browse by type"
  echo -e "    theme generate ${DIM}[dark|light]${RESET} ${DIM}[--wild] [--seed=HEX]${RESET}"
  echo -e "                                 generate random harmonious palette"
  echo -e "    theme random ${DIM}[dark|light]${RESET} ${DIM}[--no-font]${RESET}"
  echo -e "                                 random quality theme + font"
  echo -e "    theme save ${DIM}<name>${RESET}             save current palette as custom theme"
  echo -e "    theme remove ${DIM}<name>${RESET}           remove custom theme"
  echo -e "    theme font                   show current font + installed Nerd Fonts"
  echo -e "    theme font set ${DIM}<name>${RESET}        set mono Nerd Font everywhere"
  echo -e "    theme font random            random Nerd Font"
  echo -e "    theme fav                    list favorite themes"
  echo -e "    theme fav add ${DIM}[name]${RESET}        add current/named theme to favorites"
  echo -e "    theme fav rm ${DIM}<name>${RESET}         remove from favorites"
  echo -e "    theme fav next/prev          cycle through favorites"
  echo -e "    theme fav ${DIM}<N>${RESET}               apply Nth favorite"
  echo -e "    theme sync                   apply palette to all desktop configs"
  echo -e "    theme import ${DIM}[file|url]${RESET}      import theme (kitty/Xresources, or clipboard)"
  echo -e "    theme current                show current theme details"
  echo -e "    theme animations ${DIM}[on|off]${RESET}   toggle Hyprland animations"
  echo -e "    theme update                 refresh Gogh cache"
  echo -e "    theme backup                 backup all configs"
  echo ""
  echo -e "  ${DIM}Palette: ~/.config/theme/palette.conf${RESET}"
}

# --- Default: show current theme + help ---
cmd_default() {
  echo ""
  cmd_current
  cmd_help
  echo ""
}
