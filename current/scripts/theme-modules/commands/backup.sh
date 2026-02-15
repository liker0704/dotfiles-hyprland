# Backup management

# --- Backup configs before first sync ---
ensure_backup() {
  [[ -d "$BACKUP_DIR" ]] && return
  mkdir -p "$BACKUP_DIR"
  local files=(
    "$HOME/.config/hypr/UserConfigs/monochrome-colors.conf"
    "$HOME/.config/hypr/wallust/wallust-hyprland.conf"
    "$HOME/.config/waybar/style-minimal.css"
    "$HOME/.config/rofi/themes/Monochrome-Dark.rasi"
    "$HOME/.config/swaync/style.css"
    "$HOME/.config/kitty/theme.conf"
    "$ANIMATIONS_CONF"
  )
  for f in "${files[@]}"; do
    [[ -f "$f" ]] && cp "$f" "$BACKUP_DIR/$(basename "$f").bak"
  done
  echo -e "    ${DIM}Backup saved to $BACKUP_DIR${RESET}"
}

cmd_backup() {
  rm -rf "$BACKUP_DIR"
  ensure_backup
  echo -e "${GREEN}  Backup created${RESET}"
}
