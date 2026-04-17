#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for refreshing ags, waybar, rofi, swaync, wallust

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
  if [ -e "$1" ]; then
    return 0 # File exists
  else
    return 1 # File does not exist
  fi
}

# Kill already running processes (legacy bars we don't use)
_ps=(waybar swaync ags)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done

# Quickshell auto-reloads via FileView on ~/.config/theme/palette.conf — no manual refresh needed.
# Legacy waybar/swaync restarts removed; see Startup_Apps.conf (disabled) and theme sync pipeline (80-reload.sh).

# Relaunching rainbow borders if the script exists
sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
  ${UserScripts}/RainbowBorders.sh &
fi

exit 0
