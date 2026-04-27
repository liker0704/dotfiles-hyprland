#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Full system setup script for second PC
# Source system: Debian 13 (trixie) + Hyprland
# Run as regular user (will use sudo where needed)
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

log()  { echo -e "${GREEN}[+]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
err()  { echo -e "${RED}[x]${RESET} $1"; }
section() { echo -e "\n${BOLD}=== $1 ===${RESET}\n"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP_GNOME=false
SKIP_NVIDIA=false
SKIP_GAMING=false
SKIP_APPS=false
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --skip-gnome)   SKIP_GNOME=true ;;
    --skip-nvidia)  SKIP_NVIDIA=true ;;
    --skip-gaming)  SKIP_GAMING=true ;;
    --skip-apps)    SKIP_APPS=true ;;
    --dry-run)      DRY_RUN=true ;;
    -h|--help)
      echo "Usage: ./setup-second-pc.sh [flags]"
      echo "  --skip-gnome   Don't install GNOME desktop"
      echo "  --skip-nvidia  Don't install NVIDIA drivers"
      echo "  --skip-gaming  Don't install Steam/Gamescope/MangoHud"
      echo "  --skip-apps    Don't install desktop apps (GIMP, Telegram, etc)"
      echo "  --dry-run      Show what would be done"
      exit 0 ;;
  esac
done

if $DRY_RUN; then
  warn "Dry run mode — nothing will be installed"
fi

run() {
  if $DRY_RUN; then
    echo -e "  ${DIM}would run:${RESET} $*"
  else
    "$@"
  fi
}

# ============================================================
section "1. System update"
# ============================================================

run sudo apt update
run sudo apt upgrade -y

# ============================================================
section "2. Core APT packages"
# ============================================================

CORE_PKGS=(
  # Build tools
  build-essential gcc clang cmake meson pkg-config pkgconf bison flex
  doxygen scdoc git git-lfs curl wget jq tree htop btop ncdu inxi
  fastfetch tmux fzf imagemagick ffmpeg ffmpegthumbnailer scrot
  valgrind cppcheck lsof dmidecode lshw

  # Shell
  zsh

  # Hyprland deps & wayland
  wayland-protocols xwayland seatd brightnessctl playerctl pamixer
  grim slurp wl-clipboard wtype xdotool xsel xclip ydotool
  cliphist swappy wlogout sway-notification-center waybar
  nwg-displays nwg-look polkit-kde-agent-1 keyd yad zenity

  # Terminal & file managers
  kitty thunar thunar-archive-plugin nemo nautilus mousepad
  file-roller xarchiver

  # Networking & system
  network-manager network-manager-applet blueman bluetooth
  avahi-daemon cups cups-pk-helper pavucontrol pipewire-audio
  pipewire-pulse pipewire-alsa sshpass proxychains4 tcpdump
  traceroute dconf-cli

  # Fonts
  fonts-firacode fonts-cantarell fonts-noto-cjk

  # Python
  python3 python3-full python3-pip python3-venv

  # Misc CLI
  gh glab pandoc tesseract-ocr w3m

  # Docker
  docker-ce docker-ce-cli containerd.io docker-compose-plugin

  # Qt theming
  qt5ct qt5-style-kvantum qt6ct gtk2-engines-murrine

  # Media
  mpv mpv-mpris cava obs-studio

  # Display
  mesa-utils mesa-va-drivers mesa-vulkan-drivers vainfo
)

if ! $SKIP_GNOME; then
  CORE_PKGS+=(
    gnome-shell gnome-control-center gnome-tweaks gnome-terminal
    gnome-keyring gnome-settings-daemon gnome-software gdm3
    gnome-calculator gnome-disk-utility gnome-system-monitor
    eog evince file-roller seahorse baobab loupe
  )
fi

if ! $SKIP_NVIDIA; then
  CORE_PKGS+=(
    nvidia-driver nvidia-driver-libs:i386 nvidia-vaapi-driver
    nvidia-container-toolkit nvtop dkms
  )
fi

if ! $SKIP_GAMING; then
  CORE_PKGS+=(
    steam-installer gamescope mangohud mangohud:i386
    protontricks winetricks
  )
fi

if ! $SKIP_APPS; then
  CORE_PKGS+=(
    google-chrome-stable firefox-esr transmission-gtk
    qalculate-gtk gparted synaptic
  )
fi

# Add Docker repo if not present
if ! command -v docker &>/dev/null && ! $DRY_RUN; then
  log "Adding Docker APT repository..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
fi

# Add Google Chrome repo if not present
if ! command -v google-chrome-stable &>/dev/null && ! $DRY_RUN; then
  log "Adding Google Chrome APT repository..."
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg 2>/dev/null || true
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
  sudo apt update
fi

run sudo apt install -y "${CORE_PKGS[@]}" || warn "Some packages may not be available — check output above"

# ============================================================
section "3. Zsh + Oh My Zsh + Powerlevel10k"
# ============================================================

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing Oh My Zsh..."
  run sh -c 'RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  log "Installing Powerlevel10k..."
  run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  log "Installing zsh-autosuggestions..."
  run git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  log "Setting zsh as default shell..."
  run chsh -s "$(which zsh)"
fi

# ============================================================
section "4. Nix package manager"
# ============================================================

if ! command -v nix &>/dev/null; then
  log "Installing Nix (multi-user)..."
  if ! $DRY_RUN; then
    sh <(curl -L https://nixos.org/nix/install) --daemon --yes
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
  fi
fi

NIX_PKGS=(
  neovim yazi lazygit ripgrep fd discord mpvpaper spotify inter
)

for pkg in "${NIX_PKGS[@]}"; do
  log "Installing nix: $pkg"
  run env NIXPKGS_ALLOW_UNFREE=1 nix profile install "nixpkgs#$pkg" --impure 2>/dev/null || warn "Failed: $pkg"
done

# ============================================================
section "5. Homebrew"
# ============================================================

if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  if ! $DRY_RUN; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

BREW_PKGS=(spotify_player supabase tesseract)

for pkg in "${BREW_PKGS[@]}"; do
  log "Installing brew: $pkg"
  run brew install "$pkg" 2>/dev/null || warn "Failed: $pkg"
done

# ============================================================
section "6. Snap packages"
# ============================================================

if command -v snap &>/dev/null; then
  run sudo snap install clion --classic || warn "CLion snap failed"
  run sudo snap install onlyoffice-desktopeditors || warn "OnlyOffice snap failed"
  run sudo snap install spotify || warn "Spotify snap failed"
fi

# ============================================================
section "7. Flatpak packages"
# ============================================================

if command -v flatpak &>/dev/null; then
  run flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  run flatpak install -y --user flathub app.zen_browser.zen || warn "Zen Browser flatpak failed"
  run flatpak install -y flathub com.dec05eba.gpu_screen_recorder || warn "GPU Screen Recorder failed"
  run flatpak install -y flathub org.gimp.GIMP || warn "GIMP failed"
  run flatpak install -y flathub org.telegram.desktop || warn "Telegram failed"
fi

# ============================================================
section "8. NVM + Node.js"
# ============================================================

export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  log "Installing NVM..."
  if ! $DRY_RUN; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    . "$NVM_DIR/nvm.sh"
  fi
else
  . "$NVM_DIR/nvm.sh" 2>/dev/null || true
fi

if ! $DRY_RUN; then
  nvm install 22
  nvm use 22
  nvm alias default 22
fi

# Global npm packages
NPM_GLOBALS=(
  "@google/gemini-cli"
  "@openai/codex"
  "@tauri-apps/cli"
  "eas-cli"
  "pnpm"
)

for pkg in "${NPM_GLOBALS[@]}"; do
  log "Installing npm global: $pkg"
  run npm install -g "$pkg" 2>/dev/null || warn "Failed: $pkg"
done

# ============================================================
section "9. Bun"
# ============================================================

if ! command -v bun &>/dev/null; then
  log "Installing Bun..."
  if ! $DRY_RUN; then
    curl -fsSL https://bun.sh/install | bash
  fi
fi

# ============================================================
section "10. Rust (rustup)"
# ============================================================

if ! command -v rustup &>/dev/null; then
  log "Installing Rust via rustup..."
  if ! $DRY_RUN; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    . "$HOME/.cargo/env"
  fi
fi

# Cargo packages

# ============================================================
section "11. Go"
# ============================================================

if ! command -v go &>/dev/null; then
  log "Installing Go 1.24.4..."
  if ! $DRY_RUN; then
    curl -fsSL https://go.dev/dl/go1.24.4.linux-amd64.tar.gz -o /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
  fi
fi

# ============================================================
section "12. SDKMAN + Java"
# ============================================================

if [ ! -d "$HOME/.sdkman" ]; then
  log "Installing SDKMAN..."
  if ! $DRY_RUN; then
    curl -s "https://get.sdkman.io?rcupdate=false" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
  fi
fi

# ============================================================
section "13. Miniconda"
# ============================================================

if [ ! -d "$HOME/miniconda3" ]; then
  log "Installing Miniconda..."
  if ! $DRY_RUN; then
    curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3"
    rm /tmp/miniconda.sh
  fi
fi

# ============================================================
section "14. Python packages (pip)"
# ============================================================

PIP_PKGS=(
  fastapi uvicorn sqlalchemy pydantic pydantic-settings
  ruff mypy pytest pytest-asyncio httpx
  redis asyncpg alembic structlog
)

run pip3 install --user "${PIP_PKGS[@]}" 2>/dev/null || warn "Some pip packages failed"

# ============================================================
section "15. Fonts"
# ============================================================

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Copy fonts from dotfiles if available
if [ -d "$SCRIPT_DIR/fonts" ]; then
  cp -r "$SCRIPT_DIR/fonts/"* "$FONT_DIR/"
  log "Copied fonts from dotfiles"
fi

# Download Nerd Fonts if not present
install_nerd_font() {
  local name="$1"
  if [ ! -d "$FONT_DIR/$name" ] && ! ls "$FONT_DIR"/${name}* &>/dev/null; then
    log "Downloading $name Nerd Font..."
    if ! $DRY_RUN; then
      local tmpdir=$(mktemp -d)
      curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${name}.tar.xz" -o "$tmpdir/${name}.tar.xz" 2>/dev/null || {
        warn "Failed to download $name"; return
      }
      mkdir -p "$FONT_DIR/$name"
      tar -xf "$tmpdir/${name}.tar.xz" -C "$FONT_DIR/$name" 2>/dev/null || true
      rm -rf "$tmpdir"
    fi
  else
    log "$name already installed"
  fi
}

install_nerd_font "FiraCode"
install_nerd_font "JetBrainsMono"
install_nerd_font "VictorMono"
install_nerd_font "FantasqueSansMono"

run fc-cache -fv 2>/dev/null || true

# ============================================================
section "16. Dotfiles (Hyprland configs)"
# ============================================================

log "Running dotfiles install.sh..."
if [ -f "$SCRIPT_DIR/install.sh" ]; then
  run sudo bash "$SCRIPT_DIR/install.sh"
else
  warn "install.sh not found in $SCRIPT_DIR"
fi

# ============================================================
section "17. Docker post-install"
# ============================================================

if command -v docker &>/dev/null; then
  run sudo usermod -aG docker "$USER" || true
  log "Added $USER to docker group (re-login required)"
fi

# ============================================================
section "18. SSH server (for remote access)"
# ============================================================

if ! dpkg -l openssh-server &>/dev/null 2>&1; then
  run sudo apt install -y openssh-server
fi
run sudo systemctl enable ssh
run sudo systemctl start ssh
log "SSH server enabled. Connect with: ssh $USER@$(hostname -I | awk '{print $1}')"

# ============================================================
section "19. Systemd user services"
# ============================================================

USER_SERVICES=(swaync waybar pipewire pipewire-pulse wireplumber)
for svc in "${USER_SERVICES[@]}"; do
  run systemctl --user enable "$svc.service" 2>/dev/null || true
done

# ============================================================
section "20. Final config"
# ============================================================

# Timezone
run sudo timedatectl set-timezone Europe/Prague

# Locale
run sudo localectl set-locale LANG=en_US.UTF-8

# Create common dirs
mkdir -p "$HOME/projects" "$HOME/Applications" "$HOME/scripts" "$HOME/.local/bin"

# ============================================================
echo ""
echo -e "${GREEN}${BOLD}Setup complete!${RESET}"
echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo "  1. Reboot: sudo reboot"
echo "  2. Log into Hyprland session"
echo "  3. Copy SSH keys from main PC:"
echo "     scp ~/.ssh/id_ed25519* user@this-pc:~/.ssh/"
echo "  4. Clone your projects"
echo "  5. Install Cursor AppImage manually"
echo "  6. Configure NordVPN/Windscribe if needed"
echo "  7. Set up Android SDK if needed"
echo ""
echo -e "${DIM}Disk usage note: your main system uses 202GB/225GB (95%)."
echo -e "Make sure the second PC has enough storage.${RESET}"
