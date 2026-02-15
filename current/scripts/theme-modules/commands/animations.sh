# Hyprland animations toggle

# --- Animations toggle ---
cmd_animations() {
  local action="${1:-}"
  case "$action" in
    on)
      if [[ -f "$DEFAULT_ANIM" ]]; then
        cp "$DEFAULT_ANIM" "$ANIMATIONS_CONF"
      else
        cat > "$ANIMATIONS_CONF" << 'ANIMEOF'
animations {
  enabled = yes
  bezier = wind, 0.05, 0.9, 0.1, 1.05
  bezier = winIn, 0.1, 1.1, 0.1, 1.1
  bezier = winOut, 0.3, -0.3, 0, 1
  bezier = liner, 1, 1, 1, 1
  bezier = overshot, 0.05, 0.9, 0.1, 1.05
  bezier = smoothOut, 0.5, 0, 0.99, 0.99
  animation = windows, 1, 6, wind, slide
  animation = windowsIn, 1, 5, winIn, slide
  animation = windowsOut, 1, 3, smoothOut, slide
  animation = windowsMove, 1, 5, wind, slide
  animation = border, 1, 1, liner
  animation = fade, 1, 3, smoothOut
  animation = workspaces, 1, 5, overshot
}
ANIMEOF
      fi
      hyprctl reload &>/dev/null
      echo -e "  ${GREEN}Animations enabled${RESET}"
      ;;
    off)
      cat > "$ANIMATIONS_CONF" << 'ANIMEOF'
animations {
  enabled = no
}
ANIMEOF
      hyprctl reload &>/dev/null
      echo -e "  ${GREEN}Animations disabled${RESET}"
      ;;
    "")
      if grep -q "enabled = no" "$ANIMATIONS_CONF" 2>/dev/null; then
        echo -e "  Animations: ${RED}off${RESET}"
      else
        echo -e "  Animations: ${GREEN}on${RESET}"
      fi
      ;;
    *)
      echo -e "${RED}Usage: theme animations [on|off]${RESET}"
      exit 1
      ;;
  esac
}
