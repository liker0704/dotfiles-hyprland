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
  pkill -SIGUSR2 waybar
  echo -e "    ${GREEN}waybar reloaded${RESET}"
fi

# SwayNC
if pgrep -x swaync &>/dev/null; then
  swaync-client -rs &>/dev/null
  echo -e "    ${GREEN}swaync reloaded${RESET}"
fi

# --- Helper: save window position (workspace + monitor) by class ---
_save_window_pos() {
  local class_pattern="$1"
  hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
for c in json.load(sys.stdin):
  if '$class_pattern' in c.get('class','').lower():
    print(c['workspace']['id'], c['monitor']); break
" 2>/dev/null
}

# --- Helper: restore window to saved workspace + monitor ---
_restore_window_pos() {
  local class_pattern="$1" saved_ws="$2" saved_mon="$3"
  [[ -z "$saved_ws" ]] && return
  for _ in {1..20}; do
    sleep 0.3
    local addr
    addr=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
for c in json.load(sys.stdin):
  if '$class_pattern' in c.get('class','').lower():
    print(c['address']); break
" 2>/dev/null)
    if [[ -n "$addr" ]]; then
      hyprctl dispatch movetoworkspacesilent "$saved_ws,address:$addr" &>/dev/null
      # Ensure correct monitor if workspace drifted
      if [[ -n "$saved_mon" ]]; then
        local cur_mon
        cur_mon=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
for c in json.load(sys.stdin):
  if c.get('address','') == '$addr':
    print(c['monitor']); break
" 2>/dev/null)
        if [[ "$cur_mon" != "$saved_mon" ]]; then
          local mon_name
          mon_name=$(hyprctl monitors -j 2>/dev/null | python3 -c "
import json,sys
for m in json.load(sys.stdin):
  if m['id'] == $saved_mon: print(m['name']); break
" 2>/dev/null)
          [[ -n "$mon_name" ]] && hyprctl dispatch movewindow "mon:$mon_name,address:$addr" &>/dev/null
        fi
      fi
      return 0
    fi
  done
}

# Telegram Desktop
if flatpak ps 2>/dev/null | grep -q org.telegram.desktop; then
  local tg_pos
  tg_pos=$(_save_window_pos telegram)
  local tg_ws="${tg_pos%% *}" tg_mon="${tg_pos##* }"
  flatpak kill org.telegram.desktop
  sleep 0.5
  flatpak run org.telegram.desktop &>/dev/null & disown
  _restore_window_pos telegram "$tg_ws" "$tg_mon"
  echo -e "    ${GREEN}telegram restarted${RESET}"
fi
