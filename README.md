# Hyprland Dotfiles

Monochrome Hyprland setup with minimal UI and unified theming.

## Structure

```
current/
├── hypr/              # Hyprland WM config
├── kitty/             # Kitty terminal
├── nvim/              # Neovim (LazyVim)
├── rofi/              # Rofi launcher
├── swaync/            # SwayNC notifications
├── waybar/            # Waybar (minimal monochrome)
├── alacritty/         # Alacritty terminal
├── fontconfig/        # Font config
├── zellij/            # Zellij multiplexer
├── theme/             # Palette + custom themes
├── scripts/
│   ├── theme          # Theme CLI (dispatcher)
│   ├── theme-modules/ # Modular theme system
│   │   ├── lib/       #   Shared utilities
│   │   ├── commands/  #   15 command modules
│   │   └── targets/   #   12 sync targets (plugin architecture)
│   └── mpvpaper-stop  # Live wallpaper manager
├── .zshrc
└── .p10k.zsh
```

## Stack

- **WM**: Hyprland
- **Bar**: Waybar (minimal monochrome)
- **Terminal**: Kitty + Zellij + Alacritty
- **Shell**: Zsh + Oh-My-Zsh + Powerlevel10k
- **Launcher**: Rofi
- **Notifications**: SwayNC
- **Editor**: Neovim (LazyVim)
- **Browser**: Zen Browser (Flatpak)
- **Messenger**: Telegram Desktop (Flatpak)
- **Wallpapers**: swww (static) + mpvpaper (live video)
- **Theming**: `theme` — unified palette across all apps

## Install

```bash
sudo ./install.sh
```

Auto-backs up existing configs to `~/.dotfiles-backup/`, copies everything, creates `/usr/local/bin/theme` symlink, runs `theme sync`.

```bash
sudo ./install.sh --dry-run    # preview without changes
sudo ./install.sh --no-backup  # skip backup (reinstall)
sudo ./install.sh --force      # overwrite user data (palette, favorites)
sudo ./install.sh --restore    # rollback from latest backup
```

Protected files (won't overwrite unless `--force`):
- `~/.config/theme/palette.conf` — current theme
- `~/.config/theme/favorites` — favorite themes
- `~/.config/theme/custom-themes.json` — custom themes
- `~/.config/theme/config` — skip targets config

### Post-install

```bash
# Build mpvpaper from source (nix version breaks with NVIDIA)
sudo apt install libmpv-dev libwayland-dev libegl-dev wayland-protocols ninja-build meson
git clone https://github.com/GhostNaN/mpvpaper.git /tmp/mpvpaper
cd /tmp/mpvpaper && meson setup build && ninja -C build
cp build/mpvpaper build/mpvpaper-holder ~/.local/bin/

# Create video wallpapers directory
mkdir -p ~/Videos/wallpapers
```

## Theme

Unified theming across 12 apps from a single palette file (`~/.config/theme/palette.conf`).

### Sync targets
kitty, neovim, zellij, alacritty, hyprland, waybar, rofi, swaync, powerlevel10k, telegram, claude code, dconf (GTK/Qt)

Adding a new target = creating one file in `targets/`.

### Commands

```bash
theme                           # current theme + help
theme set "Tokyo Night"         # set from 364+ Gogh themes
theme search gruvbox            # fuzzy search with color preview
theme search cat --dark --good  # dark themes with quality filter
theme list dark                 # list dark themes
theme generate                  # random HSLuv palette
theme generate light --wild     # wild light palette
theme random                    # random quality theme + font
theme sync                      # apply palette to all configs
theme font set "Iosevka"        # set monospace Nerd Font everywhere
theme font random               # random Nerd Font
theme fav add                   # add current to favorites
theme fav next / prev           # cycle favorites
theme import file.conf          # import kitty/Xresources theme
theme save "My Theme"           # save current as custom
theme current                   # show current palette
theme backup                    # backup all configs
```

### Skip targets

Create `~/.config/theme/config`:
```
SKIP_TARGETS=telegram claude
```

## Key Bindings

### Hyprland
| Action | Keys |
|--------|------|
| Navigate | `Super+H/J/K/L` |
| Move window | `Super+Shift+H/J/K/L` |
| Workspaces | `Super+1-9` |
| Launcher | `Super+D` |
| Wallpaper select | `Super+W` |
| Live wallpaper | `Super+Alt+W` |
| Random wallpaper | `Ctrl+Alt+W` |

### Zellij
| Action | Keys |
|--------|------|
| New pane | `Alt+N` |
| Navigate | `Alt+H/J/K/L` |
| New tab | `Alt+T` |
| Switch tabs | `Alt+1/2/3` |
| Close pane | `Alt+X` |
| Fullscreen | `Alt+F` |

## Live Wallpapers

Video wallpapers via mpvpaper with rofi picker and auto-pause.

- `Super+Alt+W` — rofi menu to select video
- Videos: `~/Videos/wallpapers/` (mp4/webm/mkv)
- Wallpaper Engine (Steam) videos work via symlinks
- Auto-pauses when windows cover desktop

## Dependencies

```
hyprland waybar rofi swaync zellij kitty neovim alacritty
swww mpvpaper jq bc ffmpeg curl python3
zsh oh-my-zsh powerlevel10k
JetBrainsMono Nerd Font
```
