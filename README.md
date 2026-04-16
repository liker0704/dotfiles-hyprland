# Hyprland Dotfiles

Multi-theme Hyprland setup with unified theming. Ships two themes: **monochrome** (flat minimal) and **aurora** (glassy, rounded, animated).

## Structure

```
current/
├── shared/                # Theme-invariant configs
│   ├── hypr/              # Hyprland WM config (binds, rules, scripts)
│   ├── kitty/             # Kitty terminal (layout, actions)
│   ├── nvim/              # Neovim (LazyVim)
│   ├── rofi/              # Rofi launcher configs
│   ├── swaync/            # SwayNC structure (config.json)
│   ├── waybar/            # Waybar catalogs (Modules, configs, style presets)
│   ├── fontconfig/        # Font config
│   ├── theme/             # Shared theme data (favorites, gogh-themes)
│   ├── tmux/              # Tmux bindings
│   ├── scripts/
│   │   ├── theme          # Theme CLI (dispatcher)
│   │   ├── theme-modules/ # Modular theme system
│   │   │   ├── lib/       #   Shared utilities
│   │   │   ├── commands/  #   15 command modules
│   │   │   └── targets/   #   13 sync targets (plugin architecture)
│   │   ├── pc             # Multi-PC sync/SSH tool
│   │   └── kitty-raw      # No-tmux terminal helper
│   ├── .zshrc
│   └── .p10k.zsh
│
└── themes/
    ├── monochrome/        # Flat, minimal, no blur/rounding
    │   ├── waybar/        #   Flat bar CSS
    │   ├── kitty/         #   Color scheme
    │   ├── tmux/          #   Tmux colors
    │   ├── swaync/        #   Notification CSS
    │   ├── rofi/          #   Launcher theme
    │   ├── hypr/          #   Decorations (rounding=0, no blur)
    │   └── theme/         #   Palette + telegram theme
    │
    └── aurora/            # Glassy, rounded, animated
        ├── waybar/        #   Pill modules, glassmorphism
        ├── kitty/         #   Aurora color scheme
        ├── tmux/          #   Aurora tmux colors
        ├── swaync/        #   Slide-fade notifications
        ├── rofi/          #   Rounded launcher
        ├── hypr/          #   Decorations (rounding=12, blur, shadows, popin)
        ├── theme/         #   Aurora palette + matugen config
        ├── matugen/       #   Matugen templates (if engine=matugen)
        └── meta.json      #   Theme metadata
```

## Stack

- **WM**: Hyprland
- **Bar**: Waybar
- **Terminal**: Kitty + Tmux
- **Shell**: Zsh + Oh-My-Zsh + Powerlevel10k
- **Launcher**: Rofi
- **Notifications**: SwayNC
- **Editor**: Neovim (LazyVim)
- **Browser**: Zen Browser
- **Wallpapers**: swww (static) + mpvpaper (live video)
- **Theming**: `theme` CLI — unified palette across all apps

## Install

```bash
# Default (monochrome theme, arch)
sudo ./install.sh

# Pick a theme
sudo ./install.sh --theme aurora

# Specify OS (debian placeholder for future)
sudo ./install.sh --theme aurora --os arch

# Preview
sudo ./install.sh --theme aurora --dry-run
```

### Flags

| Flag | Description |
|------|-------------|
| `--theme NAME` | Theme to install (default: monochrome) |
| `--os DISTRO` | Target distro: arch / debian (default: arch) |
| `--dry-run` | Preview without changes |
| `--no-backup` | Skip backup |
| `--force` | Overwrite protected user data |
| `--restore` | Rollback from latest backup |

### How it works

1. Backs up existing configs to `~/.dotfiles-backup/`
2. Copies `shared/` configs (theme-invariant)
3. Overlays `themes/<name>/` on top (theme-specific CSS/palette/decorations)
4. Creates `/usr/local/bin/theme` symlink
5. Runs `theme sync` to apply palette to all apps
6. Writes `~/.config/dotfiles-theme` and `~/.config/dotfiles-os` markers

Protected files (won't overwrite unless `--force`):
- `~/.config/theme/palette.conf`, `favorites`, `custom-themes.json`, `config`, `gogh-themes.json`

### Aurora prerequisites

```bash
paru -S matugen  # optional: dynamic palette from wallpaper
```

## Themes

### Monochrome
Flat, minimal, no blur or rounding. Subtle white borders, disabled animations.

### Aurora
Glassy pill-shaped waybar modules, gradient accents, rounded corners (12px), Gaussian blur, shadow, popin window animation. Slide-fade swaync notifications. Supports matugen for automatic palette extraction from wallpaper.

## Theme CLI

Unified theming across 13 apps from a single palette file.

### Sync targets
kitty, neovim, hyprland, waybar, rofi, swaync, powerlevel10k, telegram, claude code, opencode, dconf, tmux, matugen

### Commands

```bash
theme                           # current theme + help
theme set "Tokyo Night"         # set from 364+ Gogh themes
theme search gruvbox            # fuzzy search with color preview
theme random                    # random quality theme + font
theme sync                      # apply palette to all configs
theme font set "Iosevka"        # set monospace Nerd Font everywhere
theme fav add                   # add current to favorites
theme save "My Theme"           # save current as custom
```

## Key Bindings

| Action | Keys |
|--------|------|
| Terminal | `Super+Enter` |
| Terminal (no tmux) | `Super+Shift+Enter` |
| Launcher | `Super+D` |
| Browser | `Super+B` |
| File manager | `Super+E` |
| Navigate | `Super+H/J/K/L` |
| Move window | `Super+Shift+H/J/K/L` |
| Resize | `Super+Ctrl+H/J/K/L` |
| Swap | `Super+Alt+H/J/K/L` |
| Workspaces | `Super+1-9` |
| Wallpaper select | `Super+W` |
| Lock screen | `Super+Shift+P` |
| Power menu | `Ctrl+Alt+P` |
| Dictation | `Super+R` |
| Focus mode | `Super+Escape` |

## Dependencies

### Arch (CachyOS)

```
hyprland waybar rofi swaync tmux kitty neovim
swww jq bc ffmpeg curl python3
zsh oh-my-zsh powerlevel10k
noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd
nautilus loupe wlogout hyprlock hypridle
```

### Optional

```
matugen        # dynamic wallpaper-based palette (aurora theme)
voxtype        # push-to-talk voice dictation
mpvpaper       # live video wallpapers
```
