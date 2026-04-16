# Qt6 theme sync via qt6ct

mkdir -p "$HOME/.config/qt6ct"

cat > "$HOME/.config/qt6ct/qt6ct.conf" << EOF
[Appearance]
custom_palette=true
standard_dialogs=default
style=kvantum

[Palette]
active_colors=#${C[fg]}, #${C[bg_light]}, #${C[bg_highlight]}, #${C[bg_light]}, #${C[fg_muted]}, #${C[fg_dim]}, #${C[fg]}, #${C[fg]}, #${C[fg]}, #${C[bg]}, #${C[bg]}, #${C[border]}, #${C[accent]:-${C[blue]}}, #${C[bg]}, #${C[accent]:-${C[blue]}}, #${C[red]}, #${C[bg_highlight]}, #${C[fg]}, #${C[bg]}, #${C[fg]}, 0.65098
inactive_colors=#${C[fg_dim]}, #${C[bg_light]}, #${C[bg_highlight]}, #${C[bg_light]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[fg_dim]}, #${C[fg_dim]}, #${C[fg_dim]}, #${C[bg]}, #${C[bg]}, #${C[border]}, #${C[accent]:-${C[blue]}}, #${C[bg]}, #${C[accent]:-${C[blue]}}, #${C[red]}, #${C[bg_highlight]}, #${C[fg]}, #${C[bg]}, #${C[fg_dim]}, 0.65098
disabled_colors=#${C[fg_muted]}, #${C[bg]}, #${C[bg_highlight]}, #${C[bg_light]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[bg]}, #${C[bg]}, #${C[border]}, #${C[accent]:-${C[blue]}}, #${C[fg_muted]}, #${C[accent]:-${C[blue]}}, #${C[red]}, #${C[bg_highlight]}, #${C[fg]}, #${C[bg]}, #${C[fg_muted]}, 0.65098

[Fonts]
fixed="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
EOF

echo -e "    ${GREEN}qt6ct${RESET}"
