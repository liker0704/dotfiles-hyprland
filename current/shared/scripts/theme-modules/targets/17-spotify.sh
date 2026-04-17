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

# Apply. Requires /opt/spotify writable (`sudo chmod -R a+wr /opt/spotify`);
# without it spicetify prints a scary "fatal: permission denied". Suppress
# stdout too so target output stays clean — user sees green label only.
spicetify config current_theme Generated >/dev/null 2>&1
spicetify apply >/dev/null 2>&1

# Detect missing perms so user gets an actionable hint instead of silence.
if [[ ! -w /opt/spotify/Apps/xpui.spa ]]; then
    echo -e "    ${GREEN}spotify (spicetify)${RESET} — config written; run 'sudo chmod -R a+wr /opt/spotify' to enable apply"
else
    echo -e "    ${GREEN}spotify (spicetify)${RESET}"
fi
