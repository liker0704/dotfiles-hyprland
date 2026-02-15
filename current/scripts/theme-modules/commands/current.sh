source "$THEME_LIB/palette.sh"

# Get current font from palette
get_current_font() {
  if [[ -f "$PALETTE" ]]; then
    grep '^font=' "$PALETTE" 2>/dev/null | cut -d= -f2-
  fi
}

# --- Show current theme ---
cmd_current() {
  if [[ ! -f "$PALETTE" ]]; then
    echo -e "  ${DIM}No palette set${RESET}"
    return 1
  fi
  local theme_name
  theme_name=$(grep -oP '# Theme: \K.*' "$PALETTE" 2>/dev/null || grep -oP '# Imported from: \K.*' "$PALETTE" 2>/dev/null || echo "custom")
  echo -e "  ${BOLD}$theme_name${RESET}"
  # Unsaved indicator for generated/imported themes
  if [[ "$theme_name" == Random* || "$theme_name" == *Imported* ]]; then
    echo -e "  ${YELLOW}unsaved${RESET} ${DIM}— theme save <name> to keep${RESET}"
  fi
  echo ""
  # Use shared read_palette
  read_palette
  # Swatch
  for name in black red green yellow blue magenta cyan white; do
    hex="${C[$name]}"
    [[ -z "$hex" ]] && continue
    r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))
    printf "\033[48;2;%d;%d;%dm  \033[0m" "$r" "$g" "$b"
  done
  echo -n " "
  for name in bright_black bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_white; do
    hex="${C[$name]}"
    [[ -z "$hex" ]] && continue
    r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))
    printf "\033[48;2;%d;%d;%dm  \033[0m" "$r" "$g" "$b"
  done
  echo ""
  echo -e "  ${DIM}bg:#${C[bg]} fg:#${C[fg]}${RESET}"
  local cur_font
  cur_font=$(get_current_font)
  [[ -n "$cur_font" ]] && echo -e "  ${DIM}font: $cur_font${RESET}"
  return 0
}
