#!/usr/bin/env bash
# Select and apply live video wallpapers via rofi menu (Super+Alt+W)

VIDEO_DIR="$HOME/Videos/wallpapers"
SCRIPTS_DIR="$HOME/.config/hypr/scripts"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
iDIR="$HOME/.config/swaync/icons"
CACHE_DIR="$HOME/.cache/video_preview"
MPVPAPER="$HOME/.local/bin/mpvpaper"

# Rofi config (same as WallpaperSelect.sh)
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "Live Wallpaper" "Could not detect focused monitor"
  exit 1
fi

# Calculate icon size (same logic as WallpaperSelect.sh)
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')
icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

# Find video wallpapers
mapfile -d '' videos < <(find -L "$VIDEO_DIR" -type f \( \
  -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.mov" \) -print0 2>/dev/null)

if [[ ${#videos[@]} -eq 0 ]]; then
  notify-send -i "$iDIR/error.png" "Live Wallpaper" "No videos in $VIDEO_DIR"
  exit 1
fi

# Generate menu with video thumbnails
menu() {
  # "Stop" option if mpvpaper is running
  if pgrep -x mpvpaper &>/dev/null; then
    printf "%s\x00icon\x1f%s\n" "⏹ Stop live wallpaper" "$iDIR/picture.png"
  fi

  # Random option
  random_vid="${videos[$((RANDOM % ${#videos[@]}))]}"
  cache_random="$CACHE_DIR/random_preview.png"
  if [[ ! -f "$cache_random" ]]; then
    mkdir -p "$CACHE_DIR"
    ffmpeg -v error -y -i "$random_vid" -ss 00:00:01.000 -vframes 1 "$cache_random" 2>/dev/null
  fi
  printf "%s\x00icon\x1f%s\n" ". random" "$cache_random"

  # Each video with thumbnail
  IFS=$'\n' sorted=($(printf '%s\n' "${videos[@]}" | sort))
  for vid in "${sorted[@]}"; do
    name=$(basename "$vid")
    cache_img="$CACHE_DIR/${name}.png"
    if [[ ! -f "$cache_img" ]]; then
      mkdir -p "$CACHE_DIR"
      ffmpeg -v error -y -i "$vid" -ss 00:00:01.000 -vframes 1 "$cache_img" 2>/dev/null
    fi
    printf "%s\x00icon\x1f%s\n" "$name" "$cache_img"
  done
}

# Apply video wallpaper
apply_video() {
  local video_path="$1"
  local video_name
  video_name=$(basename "$video_path")

  # Kill existing wallpaper processes
  pkill -x mpvpaper 2>/dev/null
  swww kill 2>/dev/null

  sleep 0.5

  # Start mpvpaper on focused monitor (-p = auto-pause when hidden)
  "$MPVPAPER" -f -p -o "load-scripts=no no-audio --loop --hwdec=auto" \
    "$focused_monitor" "$video_path"

  notify-send -i "$iDIR/picture.png" "Live Wallpaper" "Playing: $video_name" -u normal -t 3000
}

# Restore static wallpaper
restore_static() {
  pkill -x mpvpaper 2>/dev/null

  if ! pgrep -x swww-daemon &>/dev/null; then
    swww-daemon --format xrgb &
    for i in {1..50}; do
      swww query &>/dev/null && break
      sleep 0.1
    done
  fi

  # Pick random static wallpaper
  mapfile -t wallpapers < <(find -L "$WALLPAPER_DIR" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null)

  if [[ ${#wallpapers[@]} -gt 0 ]]; then
    random_wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    swww img -o "$focused_monitor" "$random_wp" \
      --transition-fps 60 --transition-type any --transition-duration 2 \
      --transition-bezier ".43,1.19,1,.4"

    "$SCRIPTS_DIR/WallustSwww.sh" "$random_wp" &
    sleep 2
    "$SCRIPTS_DIR/Refresh.sh" &
  fi

  notify-send -i "$iDIR/picture.png" "Live Wallpaper" "Stopped — static wallpaper restored" -u normal -t 3000
}

# Kill existing rofi
pidof rofi &>/dev/null && pkill rofi

# Show rofi menu
choice=$(menu | rofi -i -show -dmenu -config "$rofi_theme" -theme-str "$rofi_override")
choice=$(echo "$choice" | xargs)

[[ -z "$choice" ]] && exit 0

# Handle stop
if [[ "$choice" == *"Stop live wallpaper"* ]]; then
  restore_static
  exit 0
fi

# Handle random
if [[ "$choice" == ". random" ]]; then
  selected="${videos[$((RANDOM % ${#videos[@]}))]}"
else
  # Find selected video
  choice_base=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')
  selected=$(find -L "$VIDEO_DIR" -iname "$choice_base.*" -print -quit)
fi

if [[ -z "$selected" || ! -f "$selected" ]]; then
  notify-send -i "$iDIR/error.png" "Live Wallpaper" "File not found: $choice"
  exit 1
fi

apply_video "$selected"
