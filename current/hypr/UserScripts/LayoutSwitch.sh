#!/usr/bin/env bash
# Smart layout switch:
#   no arg : us <-> ru toggle; from Ukrainian always -> us (English)
#   "ua"   : switch directly to Ukrainian
# Layout indexes follow kb_layout = us,ru,ua

if [ "$1" = "ua" ]; then
  hyprctl switchxkblayout all 2
  exit 0
fi

current=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main) | .active_keymap')

case "$current" in
  English*) hyprctl switchxkblayout all 1 ;; # us -> ru
  *)        hyprctl switchxkblayout all 0 ;; # ru/ua -> us
esac
