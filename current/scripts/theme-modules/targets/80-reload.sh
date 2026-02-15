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

# --- Helper: save window position (workspace + monitor name) by class ---
_save_window_pos() {
  local class_pattern="$1"
  hyprctl clients -j 2>/dev/null | python3 -c "
import json,sys
clients = json.load(sys.stdin)
monitors = {m['id']: m['name'] for m in json.load(open('/dev/stdin'))} if False else {}
for c in clients:
  if '$class_pattern' in c.get('class','').lower():
    print(c['workspace']['id'], c['monitor']); break
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

# --- Helper: restore window to saved workspace on saved monitor ---
_restore_window_pos() {
  local class_pattern="$1" saved_ws="$2" saved_mon_id="$3"
  [[ -z "$saved_ws" ]] && return
  # Resolve monitor name before app restarts
  local saved_mon_name
  saved_mon_name=$(_mon_name "$saved_mon_id")
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
      # Move window to workspace
      hyprctl dispatch movetoworkspacesilent "$saved_ws,address:$addr" &>/dev/null
      # Move workspace to correct monitor (fixes focus-follows-mouse drift)
      if [[ -n "$saved_mon_name" ]]; then
        hyprctl dispatch moveworkspacetomonitor "$saved_ws" "$saved_mon_name" &>/dev/null
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
