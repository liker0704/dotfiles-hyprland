# Hyprland Dotfiles

Monochrome Hyprland setup with minimal UI.

## Structure

- `current/` - Current active configuration
- `old/` - Previous configuration (backup)

## Current Setup

- **WM**: Hyprland
- **Bar**: Waybar (minimal monochrome)
- **Terminal**: Alacritty + Zellij
- **Shell**: Zsh + Oh-My-Zsh + Powerlevel10k
- **Launcher**: Rofi
- **Notifications**: SwayNC
- **Editor**: Neovim (LazyVim)

## Color Scheme

- Background: `#18181b`
- Foreground: `#e5e7eb`
- Accent: `#ffffff` (white borders for focus)

## Key Bindings

### Zellij (Alt-based)
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

## Install

```bash
# Backup existing configs first!
cp -r current/* ~/.config/
cp current/.zshrc ~/
cp current/.p10k.zsh ~/
```
