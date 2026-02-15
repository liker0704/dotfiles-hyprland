# Reload all applications

# Kitty
if pgrep -x kitty &>/dev/null; then
  kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null
  echo -e "    ${GREEN}kitty reloaded${RESET}"
fi

# Neovim
for sock in /run/user/$(id -u)/nvim.*.0; do
  [[ -S "$sock" ]] || continue
  nvim --server "$sock" --remote-send \
    '<Cmd>source ~/.config/nvim/lua/plugins/colorscheme.lua<CR><Cmd>colorscheme tokyonight<CR>' \
    2>/dev/null && echo -e "    ${GREEN}neovim reloaded${RESET}" && break
done

# Hyprland
if pgrep -x Hyprland &>/dev/null; then
  hyprctl reload &>/dev/null
  echo -e "    ${GREEN}hyprland reloaded${RESET}"
fi

# Waybar
if pgrep -x waybar &>/dev/null; then
  pkill waybar
  sleep 0.3
  waybar &>/dev/null & disown
  echo -e "    ${GREEN}waybar restarted${RESET}"
fi

# SwayNC
if pgrep -x swaync &>/dev/null; then
  swaync-client -rs &>/dev/null
  echo -e "    ${GREEN}swaync reloaded${RESET}"
fi

# Telegram Desktop
if flatpak ps 2>/dev/null | grep -q org.telegram.desktop; then
  local tg_ws
  tg_ws=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
for c in json.load(sys.stdin):
  if 'telegram' in c.get('class','').lower():
    print(c['workspace']['id']); break
" 2>/dev/null)
  flatpak kill org.telegram.desktop
  sleep 0.5
  flatpak run org.telegram.desktop &>/dev/null & disown
  if [[ -n "$tg_ws" ]]; then
    for _ in {1..20}; do
      sleep 0.3
      local tg_addr
      tg_addr=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
for c in json.load(sys.stdin):
  if 'telegram' in c.get('class','').lower():
    print(c['address']); break
" 2>/dev/null)
      if [[ -n "$tg_addr" ]]; then
        hyprctl dispatch movetoworkspacesilent "$tg_ws,address:$tg_addr" &>/dev/null
        break
      fi
    done
  fi
  echo -e "    ${GREEN}telegram restarted${RESET}"
fi
