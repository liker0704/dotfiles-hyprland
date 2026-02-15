# Reload all applications

# Kitty
if pgrep -x kitty &>/dev/null; then
  kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null
  echo -e "    ${GREEN}kitty reloaded${RESET}"
fi

# Neovim — reload all running instances
local _nvim_ok=false
for sock in /run/user/$(id -u)/nvim.*.0; do
  [[ -S "$sock" ]] || continue
  # Skip stale sockets (process dead)
  local _pid="${sock##*/nvim.}"; _pid="${_pid%.0}"
  kill -0 "$_pid" 2>/dev/null || continue
  nvim --server "$sock" --remote-send \
    '<Cmd>luafile ~/.config/nvim/theme-reload.lua<CR>' \
    2>/dev/null && _nvim_ok=true
done
$_nvim_ok && echo -e "    ${GREEN}neovim reloaded${RESET}"

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

# --- Helper: save window state (workspace, monitor, floating) by class ---
_save_window_pos() {
  local class_pattern="$1"
  hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
for c in json.load(sys.stdin):
  if '$class_pattern' in c.get('class','').lower():
    print(c['workspace']['id'], c['monitor'], int(c.get('floating', False))); break
" 2>/dev/null
}

# --- Helper: get monitor name by ID ---
_mon_name() {
  hyprctl monitors -j 2>/dev/null | python3 -c "
import json,sys
for m in json.load(sys.stdin):
  if m['id'] == $1: print(m['name']); break
" 2>/dev/null
}

# --- Helper: restore window to saved workspace, monitor, tiling state ---
_restore_window_pos() {
  local class_pattern="$1" saved_ws="$2" saved_mon_id="$3" saved_floating="${4:-0}"
  [[ -z "$saved_ws" ]] && return
  local saved_mon_name
  saved_mon_name=$(_mon_name "$saved_mon_id")
  for _ in {1..50}; do
    sleep 0.1
    local addr
    addr=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
for c in json.load(sys.stdin):
  if '$class_pattern' in c.get('class','').lower():
    print(c['address']); break
" 2>/dev/null)
    if [[ -n "$addr" ]]; then
      sleep 0.2
      # Restore tiling state first
      local cur_floating
      cur_floating=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
for c in json.load(sys.stdin):
  if c.get('address','') == '$addr':
    print(int(c.get('floating', False))); break
" 2>/dev/null)
      if [[ "$saved_floating" == "0" && "$cur_floating" == "1" ]]; then
        hyprctl dispatch settiled "address:$addr" &>/dev/null
      elif [[ "$saved_floating" == "1" && "$cur_floating" == "0" ]]; then
        hyprctl dispatch setfloating "address:$addr" &>/dev/null
      fi
      # Move to saved workspace + monitor
      hyprctl dispatch movetoworkspacesilent "$saved_ws,address:$addr" &>/dev/null
      [[ -n "$saved_mon_name" ]] && hyprctl dispatch moveworkspacetomonitor "$saved_ws" "$saved_mon_name" &>/dev/null
      return 0
    fi
  done
}

# Telegram Desktop
if flatpak ps 2>/dev/null | grep -q org.telegram.desktop; then
  local tg_state
  tg_state=$(_save_window_pos telegram)
  local tg_ws tg_mon tg_float
  read -r tg_ws tg_mon tg_float <<< "$tg_state"
  flatpak kill org.telegram.desktop
  sleep 0.5
  flatpak run org.telegram.desktop &>/dev/null & disown
  _restore_window_pos telegram "$tg_ws" "$tg_mon" "$tg_float"
  echo -e "    ${GREEN}telegram restarted${RESET}"
fi
