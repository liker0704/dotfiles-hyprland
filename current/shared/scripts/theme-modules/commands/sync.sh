# Sync palette to all configs

apply_palette() {
  # Prevent concurrent sync runs (e.g. Super+W spam) from racing on
  # palette.conf — half-written file makes QS fall back to magenta.
  mkdir -p "$HOME/.config/theme"
  exec 9>"$HOME/.config/theme/.sync.lock"
  if ! flock -n 9; then
    echo "  sync already running, skipping"
    return 0
  fi

  # Read palette and compute derived variables
  source "$THEME_LIB/palette.sh"
  read_palette

  # Ensure backup exists
  source "$THEME_DIR/commands/backup.sh"
  ensure_backup

  # Load skip list from config
  local -a skip_targets=()
  local config_file="$HOME/.config/theme/config"
  if [[ -f "$config_file" ]]; then
    local skip_line
    skip_line=$(grep '^SKIP_TARGETS=' "$config_file" 2>/dev/null | cut -d= -f2-)
    if [[ -n "$skip_line" ]]; then
      read -ra skip_targets <<< "$skip_line"
    fi
  fi

  echo "  Syncing..."

  # Source all target plugins in order (skip if in skip list)
  for target in "$THEME_DIR/targets/"*.sh; do
    [[ -f "$target" ]] || continue
    local target_name
    target_name=$(basename "$target" .sh)
    target_name="${target_name#[0-9][0-9]-}"
    local skip=false
    for s in "${skip_targets[@]}"; do
      [[ "$target_name" == "$s" ]] && skip=true && break
    done
    $skip && continue
    source "$target"
  done

  echo -e "  ${BOLD}Done!${RESET}"
}

cmd_sync() {
  apply_palette
}
