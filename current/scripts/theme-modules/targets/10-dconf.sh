# System color-scheme (GTK/Qt/browsers via xdg-desktop-portal)

if command -v dconf &>/dev/null; then
  if $is_light; then
    dconf write /org/gnome/desktop/interface/color-scheme "'default'"
  else
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
  fi
fi
echo -e "    ${GREEN}dconf${RESET}"
