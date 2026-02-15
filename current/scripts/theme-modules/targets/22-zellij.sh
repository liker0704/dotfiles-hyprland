# Zellij terminal multiplexer theme

local ZELLIJ_CONF="$HOME/.config/zellij/config.kdl"
if [[ -f "$ZELLIJ_CONF" ]]; then
  sed -i '/^\/\/ THEME-SYNC START/,/^\/\/ THEME-SYNC END/d' "$ZELLIJ_CONF"
  sed -i 's/^theme ".*"/theme "synced"/' "$ZELLIJ_CONF"
  cat >> "$ZELLIJ_CONF" << EOF
// THEME-SYNC START
themes {
  synced {
    bg "#${C[bg_light]}"
    fg "#${C[fg]}"
    black "#${C[black]}"
    red "#${C[red]}"
    green "#${C[green]}"
    yellow "#${C[yellow]}"
    blue "#${C[blue]}"
    magenta "#${C[magenta]}"
    cyan "#${C[cyan]}"
    white "#${C[white]}"
    orange "#${C[yellow]}"
  }
}
// THEME-SYNC END
EOF
  echo -e "    ${GREEN}zellij${RESET}"
fi
