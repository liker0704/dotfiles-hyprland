# Spotify theme sync via spicetify

command -v spicetify &>/dev/null || return 0

local SPICETIFY_DIR="$HOME/.config/spicetify/Themes/Generated"
mkdir -p "$SPICETIFY_DIR"

cat > "$SPICETIFY_DIR/color.ini" << EOF
[Base]
text               = ${C[fg]}
subtext            = ${C[fg_dim]}
sidebar-text       = ${C[fg]}
main               = ${C[bg]}
sidebar            = ${C[bg_light]}
player             = ${C[bg]}
card               = ${C[bg_light]}
shadow             = ${C[black]}
selected-row       = ${C[bg_highlight]}
button             = ${C[accent]:-${C[blue]}}
button-active      = ${C[accent]:-${C[blue]}}
button-disabled    = ${C[fg_muted]}
tab-active         = ${C[accent]:-${C[blue]}}
notification       = ${C[green]}
notification-error = ${C[red]}
misc               = ${C[border]}
EOF

cat > "$SPICETIFY_DIR/user.css" << 'EOF'
/* minimal — just colors */
EOF

# Apply
spicetify config current_theme Generated 2>/dev/null
spicetify apply 2>/dev/null

echo -e "    ${GREEN}spotify (spicetify)${RESET}"
