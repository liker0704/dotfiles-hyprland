# Sync palette to all configs

apply_palette() {
  # Prevent concurrent sync runs (Super+W spam) from racing on palette.conf —
  # half-written file makes QS fall back to magenta. PID-based staleness
  # check handles phantom locks left by crashed processes (kernel sometimes
  # doesn't release flock on abnormal exit).
  mkdir -p "$HOME/.config/theme"
  local lock_file="$HOME/.config/theme/.sync.lock"

  for attempt in 1 2; do
    exec 9>"$lock_file"
    if flock -n 9; then
      echo $$ >&9
      break
    fi
    # flock failed — is the holder actually alive?
    local holder
    holder=$(cat "$lock_file" 2>/dev/null)
    if [[ -z "$holder" ]] || ! kill -0 "$holder" 2>/dev/null; then
      # Phantom lock (dead PID). Remove file to force new inode on retry.
      rm -f "$lock_file"
      continue
    fi
    echo "  sync already running (pid $holder), skipping"
    return 0
  done

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
