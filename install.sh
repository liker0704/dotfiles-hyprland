#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$REPO_DIR/current"
SHARED_SRC="$SRC/shared"
BACKUP_BASE="$HOME/.dotfiles-backup"

# --- Flags ---
DRY_RUN=false
NO_BACKUP=false
FORCE=false
RESTORE=""
THEME="monochrome"
OS="arch"

usage() {
  cat <<EOF
Usage: sudo ./install.sh [flags]

Flags:
  --theme NAME     Theme to install (default: monochrome)
                   Available: $(ls "$SRC/themes" 2>/dev/null | tr '\n' ' ')
  --os DISTRO      Target distro: arch | debian (default: arch)
                   (debian placeholder — only arch is supported right now)
  --dry-run        Show what would be done
  --no-backup      Skip backup
  --force          Overwrite protected user data (palette, favorites)
  --restore        Restore from latest backup
  --restore=DIR    Restore from specific backup
  -h, --help       This help
EOF
}

# --- Flag parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --theme)      THEME="$2"; shift 2 ;;
    --theme=*)    THEME="${1#--theme=}"; shift ;;
    --os)         OS="$2"; shift 2 ;;
    --os=*)       OS="${1#--os=}"; shift ;;
    --dry-run)    DRY_RUN=true; shift ;;
    --no-backup)  NO_BACKUP=true; shift ;;
    --force)      FORCE=true; shift ;;
    --restore)    RESTORE="latest"; shift ;;
    --restore=*)  RESTORE="${1#--restore=}"; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo -e "${RED}Unknown flag: $1${RESET}"; usage; exit 1 ;;
  esac
done

THEME_SRC="$SRC/themes/$THEME"

# --- Detect real user (script runs with sudo) ---
if [[ -n "${SUDO_USER:-}" ]]; then
  REAL_USER="$SUDO_USER"
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
else
  REAL_USER="$(whoami)"
  REAL_HOME="$HOME"
fi

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

# --- Validate theme ---
if [[ ! -d "$THEME_SRC" ]]; then
  echo -e "${RED}Theme '$THEME' not found in $SRC/themes/${RESET}"
  echo "Available: $(ls "$SRC/themes" 2>/dev/null | tr '\n' ' ')"
  exit 1
fi

# --- Validate OS ---
case "$OS" in
  arch) ;;
  debian) echo -e "${YELLOW}Note: --os debian is a placeholder; Debian packaging is not yet implemented. Dotfiles will still copy.${RESET}" ;;
  *) echo -e "${RED}Unknown --os: $OS (expected: arch | debian)${RESET}"; exit 1 ;;
esac

# --- Mappings ---
# src_under_shared_or_theme:dst
#
# DIR_MAPS are copied from BOTH shared/ (if present) and themes/$THEME/ (if present).
# Theme overlays shared — shared copies first, theme copies on top.
DIR_MAPS=(
  "hypr:$REAL_HOME/.config/hypr"
  "kitty:$REAL_HOME/.config/kitty"
  "nvim:$REAL_HOME/.config/nvim"
  "rofi:$REAL_HOME/.config/rofi"
  "swaync:$REAL_HOME/.config/swaync"
  "waybar:$REAL_HOME/.config/waybar"
  "fontconfig:$REAL_HOME/.config/fontconfig"
  "tmux:$REAL_HOME/.config/tmux"
  "theme:$REAL_HOME/.config/theme"
)

# file:dst (shared only; themes typically use DIR_MAPS)
FILE_MAPS=(
  "scripts/theme:$REAL_HOME/.local/bin/theme"
  "scripts/mpvpaper-stop:$REAL_HOME/.local/bin/mpvpaper-stop"
  "scripts/pc:$REAL_HOME/.local/bin/pc"
  "scripts/kitty-raw:$REAL_HOME/.local/bin/kitty-raw"
  "scripts/obsidian:$REAL_HOME/.local/bin/obsidian"
  "scripts/obsidian-notes:$REAL_HOME/.local/bin/obsidian-notes"
  "scripts/note:$REAL_HOME/.local/bin/note"
  "applications/obsidian-mainvault.desktop:$REAL_HOME/.local/share/applications/obsidian-mainvault.desktop"
  "applications/nvim.desktop:$REAL_HOME/.local/share/applications/nvim.desktop"
  "mimeapps.list:$REAL_HOME/.config/mimeapps.list"
  ".zshrc:$REAL_HOME/.zshrc"
  ".p10k.zsh:$REAL_HOME/.p10k.zsh"
)

# special dir mapping (shared only)
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

# Copy a directory from source root.
# Respects PROTECTED paths (skips files that already exist and are protected).
copy_dir() {
  local abs_src="$1" abs_dst="$2" label="$3"
  [[ ! -d "$abs_src" ]] && return
  mkdir -p "$abs_dst"
  # Walk each top-level entry; recurse with cp -a except for protected files
  local had_protected=0
  while IFS= read -r -d '' f; do
    local rel="${f#$abs_src/}"
    local target="$abs_dst/$rel"
    if is_protected "$target" && [[ -f "$target" ]]; then
      log_skip "${label}/${rel}"
      had_protected=1
    else
      mkdir -p "$(dirname "$target")"
      if [[ -d "$f" ]]; then
        mkdir -p "$target"
        cp -a "$f"/. "$target/"
      else
        cp -a "$f" "$target"
      fi
    fi
  done < <(find "$abs_src" -mindepth 1 -maxdepth 1 -print0)
  (( had_protected == 0 )) && log_ok "${label}/"
  return 0
}

copy_file() {
  local abs_src="$1" abs_dst="$2" label="$3"
  [[ ! -f "$abs_src" ]] && return
  mkdir -p "$(dirname "$abs_dst")"
  cp -a "$abs_src" "$abs_dst"
  log_ok "${label}"
}

# --- Dry run ---
if $DRY_RUN; then
  echo -e "${BOLD}Dry run — nothing will be changed${RESET}"
  echo -e "Theme: ${GREEN}${THEME}${RESET}  OS: ${GREEN}${OS}${RESET}\n"
  echo -e "${BOLD}Shared dirs ($SHARED_SRC/ → ~/.config/...):${RESET}"
  for map in "${DIR_MAPS[@]}"; do
    src="${map%%:*}"; dst="${map#*:}"
    [[ -d "$SHARED_SRC/$src" ]] && log_dry "$src/ → $dst/"
  done
  echo -e "\n${BOLD}Theme dirs ($THEME_SRC/ → ~/.config/...):${RESET}"
  for map in "${DIR_MAPS[@]}"; do
    src="${map%%:*}"; dst="${map#*:}"
    [[ -d "$THEME_SRC/$src" ]] && log_dry "$src/ → $dst/ ${DIM}(overlays shared)${RESET}"
  done
  echo -e "\n${BOLD}Special dirs:${RESET}"
  for map in "${SPECIAL_DIR_MAPS[@]}"; do
    src="${map%%:*}"; dst="${map#*:}"
    [[ -d "$SHARED_SRC/$src" ]] && log_dry "$src/ → $dst/"
  done
  echo -e "\n${BOLD}Files:${RESET}"
  for map in "${FILE_MAPS[@]}"; do
    src="${map%%:*}"; dst="${map#*:}"
    [[ -f "$SHARED_SRC/$src" ]] && log_dry "$src → $dst"
  done
  echo -e "\n${BOLD}Protected (won't overwrite if exist):${RESET}"
  for p in "${PROTECTED[@]}"; do
    [[ -f "$p" ]] && log_skip "$p" || log_dry "$p ${DIM}(missing, will create)${RESET}"
  done
  echo -e "\n${BOLD}Symlink:${RESET}"
  log_dry "/usr/local/bin/theme → $REAL_HOME/.local/bin/theme"
  echo -e "\n${BOLD}Post-install:${RESET}"
  log_dry "mark active theme: ~/.config/dotfiles-theme = $THEME"
  log_dry "mark os: ~/.config/dotfiles-os = $OS"
  log_dry "theme sync"
  exit 0
fi

echo -e "${BOLD}Theme:${RESET} ${GREEN}$THEME${RESET}  ${BOLD}OS:${RESET} ${GREEN}$OS${RESET}\n"

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

# --- Install shared dirs ---
echo -e "${BOLD}Installing shared configs...${RESET}"
for map in "${DIR_MAPS[@]}"; do
  src="${map%%:*}"; dst="${map#*:}"
  copy_dir "$SHARED_SRC/$src" "$dst" "shared/$src"
done

# --- Overlay theme dirs ---
echo ""
echo -e "${BOLD}Overlaying theme '$THEME'...${RESET}"
for map in "${DIR_MAPS[@]}"; do
  src="${map%%:*}"; dst="${map#*:}"
  copy_dir "$THEME_SRC/$src" "$dst" "themes/$THEME/$src"
done

# Special dir mappings (shared only)
echo ""
for map in "${SPECIAL_DIR_MAPS[@]}"; do
  src="${map%%:*}"; dst="${map#*:}"
  [[ ! -d "$SHARED_SRC/$src" ]] && continue
  mkdir -p "$dst"
  cp -a "$SHARED_SRC/$src"/. "$dst/"
  log_ok "shared/$src/ → ${dst#$REAL_HOME/}"
done

# --- Install files (shared only) ---
echo ""
for map in "${FILE_MAPS[@]}"; do
  src="${map%%:*}"; dst="${map#*:}"
  copy_file "$SHARED_SRC/$src" "$dst" "shared/${src} → ${dst#$REAL_HOME/}"
done

# Make scripts executable — covers every .sh / .py in user-script dirs.
# cp -a should preserve bits, but on copy from FAT/NTFS or via clipboard /
# rsync-without-p the +x bit is lost — set it explicitly to be safe.
chmod +x "$REAL_HOME/.local/bin/theme" \
         "$REAL_HOME/.local/bin/mpvpaper-stop" \
         "$REAL_HOME/.local/bin/pc" \
         "$REAL_HOME/.local/bin/kitty-raw" \
         "$REAL_HOME/.local/bin/obsidian" \
         "$REAL_HOME/.local/bin/obsidian-notes" \
         "$REAL_HOME/.local/bin/note" 2>/dev/null || true

for _script_dir in \
  "$REAL_HOME/.local/bin" \
  "$REAL_HOME/.local/share/theme/targets" \
  "$REAL_HOME/.local/share/theme/lib" \
  "$REAL_HOME/.local/share/theme/commands" \
  "$REAL_HOME/.config/hypr/scripts" \
  "$REAL_HOME/.config/hypr/UserScripts" \
  "$REAL_HOME/.claude/hooks"; do
  [[ -d "$_script_dir" ]] || continue
  find "$_script_dir" -maxdepth 2 -type f \( -name "*.sh" -o -name "*.py" \) \
    -exec chmod +x {} + 2>/dev/null || true
done

# --- Fix ownership (running as sudo) ---
# BACKUP_BASE is created during backup step ~line 239 as root since we run
# under sudo — without this chown it stayed root:root and polluted HOME.
chown -R "$REAL_USER:$REAL_USER" \
  "$REAL_HOME/.config" \
  "$REAL_HOME/.local/bin" \
  "$REAL_HOME/.local/share/applications" \
  "$REAL_HOME/.local/share/theme" \
  "$REAL_HOME/.zshrc" \
  "$REAL_HOME/.p10k.zsh" \
  "$BACKUP_BASE" \
  2>/dev/null || true

# --- Meta markers ---
echo "$THEME" | sudo -u "$REAL_USER" tee "$REAL_HOME/.config/dotfiles-theme" >/dev/null
echo "$OS" | sudo -u "$REAL_USER" tee "$REAL_HOME/.config/dotfiles-os" >/dev/null
log_ok "marked theme: $THEME, os: $OS"

# --- tmux plugins ---
TMUX_PLUGINS="$REAL_HOME/.tmux/plugins"
declare -A TMUX_REPOS=(
  [tmux-resurrect]="https://github.com/tmux-plugins/tmux-resurrect"
  [tmux-continuum]="https://github.com/tmux-plugins/tmux-continuum"
)
for plugin in "${!TMUX_REPOS[@]}"; do
  if [[ ! -d "$TMUX_PLUGINS/$plugin" ]]; then
    sudo -u "$REAL_USER" git clone --depth 1 "${TMUX_REPOS[$plugin]}" "$TMUX_PLUGINS/$plugin" >/dev/null 2>&1
    log_ok "tmux plugin: $plugin (installed)"
  else
    log_ok "tmux plugin: $plugin (exists)"
  fi
done

# --- Symlink for theme CLI ---
echo ""
ln -sf "$REAL_HOME/.local/bin/theme" /usr/local/bin/theme
log_ok "/usr/local/bin/theme → ~/.local/bin/theme"

# --- Post-install ---
echo ""
echo -e "${BOLD}Running theme sync...${RESET}"
sudo -u "$REAL_USER" "$REAL_HOME/.local/bin/theme" sync 2>&1 || true

echo ""
echo -e "${GREEN}${BOLD}Done!${RESET}  ${DIM}(theme: $THEME, os: $OS)${RESET}"
[[ -n "${BACKUP_DIR:-}" ]] && echo -e "${DIM}Backup: $BACKUP_DIR${RESET}"
