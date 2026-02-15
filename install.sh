#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$REPO_DIR/current"
BACKUP_BASE="$HOME/.dotfiles-backup"

# --- Flags ---
DRY_RUN=false
NO_BACKUP=false
FORCE=false
RESTORE=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)    DRY_RUN=true ;;
    --no-backup)  NO_BACKUP=true ;;
    --force)      FORCE=true ;;
    --restore)    RESTORE="latest" ;;
    --restore=*)  RESTORE="${arg#--restore=}" ;;
    -h|--help)
      echo "Usage: sudo ./install.sh [flags]"
      echo "  --dry-run     Show what would be done"
      echo "  --no-backup   Skip backup"
      echo "  --force       Overwrite protected user data (palette, favorites)"
      echo "  --restore     Restore from latest backup"
      echo "  --restore=DIR Restore from specific backup"
      exit 0 ;;
    *) echo -e "${RED}Unknown flag: $arg${RESET}"; exit 1 ;;
  esac
done

# --- Detect real user (script runs with sudo) ---
if [[ -n "${SUDO_USER:-}" ]]; then
  REAL_USER="$SUDO_USER"
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
else
  REAL_USER="$(whoami)"
  REAL_HOME="$HOME"
fi

# Update paths for real user
SRC="$REPO_DIR/current"
BACKUP_BASE="$REAL_HOME/.dotfiles-backup"

# --- Restore mode ---
if [[ -n "$RESTORE" ]]; then
  if [[ "$RESTORE" == "latest" ]]; then
    RESTORE=$(ls -1d "$BACKUP_BASE"/*/  2>/dev/null | sort | tail -1)
    [[ -z "$RESTORE" ]] && { echo -e "${RED}No backups found${RESET}"; exit 1; }
  fi
  RESTORE="${RESTORE%/}"
  [[ ! -d "$RESTORE" ]] && { echo -e "${RED}Backup not found: $RESTORE${RESET}"; exit 1; }
  echo -e "${BOLD}Restoring from:${RESET} $RESTORE"
  cp -r "$RESTORE"/. "$REAL_HOME/"
  chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config" "$REAL_HOME/.local" 2>/dev/null || true
  echo -e "${GREEN}Restored!${RESET}"
  exit 0
fi

# --- Mappings ---
# dir:src → dst
DIR_MAPS=(
  "hypr:$REAL_HOME/.config/hypr"
  "kitty:$REAL_HOME/.config/kitty"
  "nvim:$REAL_HOME/.config/nvim"
  "rofi:$REAL_HOME/.config/rofi"
  "swaync:$REAL_HOME/.config/swaync"
  "waybar:$REAL_HOME/.config/waybar"
  "alacritty:$REAL_HOME/.config/alacritty"
  "fontconfig:$REAL_HOME/.config/fontconfig"
  "zellij:$REAL_HOME/.config/zellij"
  "theme:$REAL_HOME/.config/theme"
)

# file:src → dst
FILE_MAPS=(
  "scripts/theme:$REAL_HOME/.local/bin/theme"
  "scripts/mpvpaper-stop:$REAL_HOME/.local/bin/mpvpaper-stop"
  ".zshrc:$REAL_HOME/.zshrc"
  ".p10k.zsh:$REAL_HOME/.p10k.zsh"
)

# special dir mapping
SPECIAL_DIR_MAPS=(
  "scripts/theme-modules:$REAL_HOME/.local/share/theme"
)

# Protected files (user data, don't overwrite unless --force)
PROTECTED=(
  "$REAL_HOME/.config/theme/palette.conf"
  "$REAL_HOME/.config/theme/favorites"
  "$REAL_HOME/.config/theme/custom-themes.json"
  "$REAL_HOME/.config/theme/config"
  "$REAL_HOME/.config/theme/gogh-themes.json"
)

# --- Helpers ---
is_protected() {
  $FORCE && return 1
  for p in "${PROTECTED[@]}"; do
    [[ "$1" == "$p" ]] && return 0
  done
  return 1
}

do_backup() {
  local src="$1"
  [[ ! -e "$src" ]] && return
  local rel="${src#$REAL_HOME/}"
  local dst="$BACKUP_DIR/$rel"
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
}

log_ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
log_skip() { echo -e "  ${YELLOW}~${RESET} $1 ${DIM}(protected)${RESET}"; }
log_dry()  { echo -e "  ${DIM}→${RESET} $1"; }

# --- Dry run ---
if $DRY_RUN; then
  echo -e "${BOLD}Dry run — nothing will be changed${RESET}\n"
  echo -e "${BOLD}Directories:${RESET}"
  for map in "${DIR_MAPS[@]}"; do
    src="${map%%:*}"; dst="${map#*:}"
    log_dry "$SRC/$src/ → $dst/"
  done
  for map in "${SPECIAL_DIR_MAPS[@]}"; do
    src="${map%%:*}"; dst="${map#*:}"
    log_dry "$SRC/$src/ → $dst/"
  done
  echo -e "\n${BOLD}Files:${RESET}"
  for map in "${FILE_MAPS[@]}"; do
    src="${map%%:*}"; dst="${map#*:}"
    log_dry "$SRC/$src → $dst"
  done
  echo -e "\n${BOLD}Protected (won't overwrite if exist):${RESET}"
  for p in "${PROTECTED[@]}"; do
    [[ -f "$p" ]] && log_skip "$p" || log_dry "$p ${DIM}(missing, will create)${RESET}"
  done
  echo -e "\n${BOLD}Symlink:${RESET}"
  log_dry "/usr/local/bin/theme → $REAL_HOME/.local/bin/theme"
  echo -e "\n${BOLD}Post-install:${RESET}"
  log_dry "theme sync"
  exit 0
fi

# --- Backup ---
if ! $NO_BACKUP; then
  BACKUP_DIR="$BACKUP_BASE/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  echo -e "${BOLD}Backup:${RESET} $BACKUP_DIR"

  for map in "${DIR_MAPS[@]}"; do
    dst="${map#*:}"
    [[ -d "$dst" ]] && do_backup "$dst"
  done
  for map in "${SPECIAL_DIR_MAPS[@]}"; do
    dst="${map#*:}"
    [[ -d "$dst" ]] && do_backup "$dst"
  done
  for map in "${FILE_MAPS[@]}"; do
    dst="${map#*:}"
    [[ -f "$dst" ]] && do_backup "$dst"
  done
  echo ""
fi

# --- Install directories ---
echo -e "${BOLD}Installing configs...${RESET}"

for map in "${DIR_MAPS[@]}"; do
  src="${map%%:*}"; dst="${map#*:}"
  [[ ! -d "$SRC/$src" ]] && continue
  mkdir -p "$dst"

  # For theme dir, handle protected files
  if [[ "$src" == "theme" ]]; then
    # Copy non-protected files
    for f in "$SRC/$src"/*; do
      fname=$(basename "$f")
      target="$dst/$fname"
      if is_protected "$target" && [[ -f "$target" ]]; then
        log_skip "$src/$fname"
      else
        cp -a "$f" "$target"
      fi
    done
    log_ok "$src/"
  else
    cp -a "$SRC/$src"/. "$dst/"
    log_ok "$src/"
  fi
done

# Special dir mappings
for map in "${SPECIAL_DIR_MAPS[@]}"; do
  src="${map%%:*}"; dst="${map#*:}"
  [[ ! -d "$SRC/$src" ]] && continue
  mkdir -p "$dst"
  cp -a "$SRC/$src"/. "$dst/"
  log_ok "$src/ → ${dst#$REAL_HOME/}"
done

# --- Install files ---
echo ""
for map in "${FILE_MAPS[@]}"; do
  src="${map%%:*}"; dst="${map#*:}"
  [[ ! -f "$SRC/$src" ]] && continue
  mkdir -p "$(dirname "$dst")"
  cp -a "$SRC/$src" "$dst"
  log_ok "${src} → ${dst#$REAL_HOME/}"
done

# Make scripts executable
chmod +x "$REAL_HOME/.local/bin/theme" "$REAL_HOME/.local/bin/mpvpaper-stop" 2>/dev/null

# --- Fix ownership (running as sudo) ---
chown -R "$REAL_USER:$REAL_USER" \
  "$REAL_HOME/.config" \
  "$REAL_HOME/.local/bin" \
  "$REAL_HOME/.local/share/theme" \
  "$REAL_HOME/.zshrc" \
  "$REAL_HOME/.p10k.zsh" \
  2>/dev/null || true

# --- Symlink for rofi ---
echo ""
ln -sf "$REAL_HOME/.local/bin/theme" /usr/local/bin/theme
log_ok "/usr/local/bin/theme → ~/.local/bin/theme"

# --- Post-install ---
echo ""
echo -e "${BOLD}Running theme sync...${RESET}"
sudo -u "$REAL_USER" "$REAL_HOME/.local/bin/theme" sync 2>&1 || true

echo ""
echo -e "${GREEN}${BOLD}Done!${RESET}"
[[ -n "${BACKUP_DIR:-}" ]] && echo -e "${DIM}Backup: $BACKUP_DIR${RESET}"
