# Hyprland Dotfiles

Monochrome Hyprland setup with minimal UI and unified theming.

## Structure

- `current/` - Current active configuration
- `old/` - Previous configuration (backup)

## Current Setup

- **WM**: Hyprland
- **Bar**: Waybar (minimal monochrome)
- **Terminal**: Kitty + Zellij
- **Shell**: Zsh + Oh-My-Zsh + Powerlevel10k
- **Launcher**: Rofi
- **Notifications**: SwayNC
- **Editor**: Neovim (LazyVim)
- **Wallpapers**: swww (static) + mpvpaper (live video)
- **Theming**: theme (unified palette for kitty/neovim/zellij)

## Color Scheme

Managed via `theme` — single palette for all tools.

- Background: `#18181b` (zinc-900)
- Foreground: `#e5e7eb` (zinc-200)
- Accent colors: Tokyo Night palette
- 364 Gogh themes available via `theme set <name>`

## Key Bindings

### Zellij (Alt-based, always available in locked mode)
| Action | Keys |
|--------|------|
| New pane | `Alt+N` |
| Navigate | `Alt+H/J/K/L` |
| New tab | `Alt+T` |
| Switch tabs | `Alt+1/2/3` |
| Close pane | `Alt+X` |
| Fullscreen | `Alt+F` |

### Hyprland
| Action | Keys |
|--------|------|
| Navigate | `Super+H/J/K/L` |
| Move window | `Super+Shift+H/J/K/L` |
| Workspaces | `Super+1-9` |
| Wallpaper select | `Super+W` |
| Live wallpaper | `Super+Alt+W` |
| Random wallpaper | `Ctrl+Alt+W` |

## Theme

Unified theming across kitty, neovim, and zellij from a single palette file.

```bash
theme                       # show current theme + available commands
theme set "Gruvbox"         # set theme from 364 Gogh themes
theme search cat            # search themes (fuzzy, with color preview)
theme sync                  # apply palette to all configs
theme current               # show current theme details
theme import file.conf      # import kitty theme file
```

Palette: `~/.config/theme/palette.conf`

## Live Wallpapers

Video wallpapers via mpvpaper with rofi picker and auto-pause.

- `Super+Alt+W` — rofi menu to select video wallpaper
- Videos go in `~/Videos/wallpapers/` (mp4/webm/mkv)
- Wallpaper Engine (Steam) videos work via symlinks
- `-p` flag auto-pauses when windows cover desktop

## Dependencies

```
hyprland waybar rofi swaync zellij kitty neovim
swww mpvpaper jq bc ffmpeg curl python3
zsh oh-my-zsh powerlevel10k
JetBrainsMono Nerd Font
```

## Install

```bash
# 1. Backup existing configs
cp -r ~/.config/hypr ~/.config/hypr.bak

# 2. Copy configs
cp -r current/hypr ~/.config/
cp -r current/kitty ~/.config/
cp -r current/zellij ~/.config/
cp -r current/nvim ~/.config/
cp -r current/rofi ~/.config/
cp -r current/swaync ~/.config/
cp -r current/waybar ~/.config/
cp -r current/fontconfig ~/.config/
cp -r current/theme ~/.config/
cp current/.zshrc ~/
cp current/.p10k.zsh ~/

# 3. Install scripts
cp current/scripts/theme ~/.local/bin/
cp current/scripts/mpvpaper-stop ~/.local/bin/
chmod +x ~/.local/bin/theme ~/.local/bin/mpvpaper-stop

# 4. Build mpvpaper from source (nix version breaks with NVIDIA)
sudo apt install libmpv-dev libwayland-dev libegl-dev wayland-protocols ninja-build meson
git clone https://github.com/GhostNaN/mpvpaper.git /tmp/mpvpaper
cd /tmp/mpvpaper && meson setup build && ninja -C build
cp build/mpvpaper build/mpvpaper-holder ~/.local/bin/

# 5. Apply theme
theme sync

# 6. Create video wallpapers directory
mkdir -p ~/Videos/wallpapers
```
