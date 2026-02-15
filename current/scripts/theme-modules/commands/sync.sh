# Sync palette to all configs

apply_palette() {
  # Read palette and compute derived variables
  source "$THEME_LIB/palette.sh"
  read_palette

  # Ensure backup exists
  source "$THEME_DIR/commands/backup.sh"
  ensure_backup

  echo "  Syncing..."

  # Source all target plugins in order
  for target in "$THEME_DIR/targets/"*.sh; do
    [[ -f "$target" ]] && source "$target"
  done

  echo -e "  ${BOLD}Done!${RESET} Restart zellij to apply."
}

cmd_sync() {
  apply_palette
}
