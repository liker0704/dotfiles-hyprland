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
main-elevated      = ${C[bg_light]}
highlight          = ${C[bg_light]}
highlight-elevated = ${C[bg_highlight]}
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

# user.css — overrides for new Global Navigation bar. Spotify's new top-bar
# uses hardcoded CSS classes that read internal vars not always exposed via
# color.ini, so we force them onto --spice-* values here.
cat > "$SPICETIFY_DIR/user.css" << 'EOF'
/* Global navigation (top bar) */
.Root__globalNav,
.Root__top-container,
.main-topBar-background,
.main-topBar-container,
.main-topBar-topbarContent,
.main-topBar-topbarContentWrapper,
.main-topBar-topbarContentContainer {
    background-color: var(--spice-main) !important;
    color: var(--spice-text) !important;
}

/* History buttons (back/forward) and Home pill */
.main-globalNav-historyButtons button,
.main-globalNav-historyButtonsContainer button,
.main-globalNav-navLink,
.main-globalNav-link-icon {
    background-color: var(--spice-card) !important;
    color: var(--spice-text) !important;
}

.main-globalNav-historyButtons svg,
.main-globalNav-historyButtonsContainer svg,
.main-globalNav-navLink svg,
.main-globalNav-link-icon svg {
    fill: var(--spice-text) !important;
    color: var(--spice-text) !important;
}

/* Search bar inside top-bar */
.main-globalNav-searchContainer,
.main-globalNav-searchInputContainer,
.main-globalNav-searchInputWrapper,
.main-globalNav-searchInputSection {
    background-color: var(--spice-card) !important;
    color: var(--spice-text) !important;
}

.main-globalNav-searchInputText,
.main-globalNav-searchInputTextWrapper {
    color: var(--spice-text) !important;
}

.main-globalNav-searchInputText::placeholder {
    color: var(--spice-subtext) !important;
}

/* Now-playing bar (bottom): right-side controls — queue / connect / volume /
 * lyrics / extras. Their SVG icons use currentColor, so forcing `color` on
 * the buttons recolors the icons. */
.main-nowPlayingBar-right,
.main-nowPlayingBar-extraControls,
.main-nowPlayingBar-volumeBar,
.main-nowPlayingBar-lyricsButton,
.main-connectBar-connectBar,
.main-connectBar-icon {
    color: var(--spice-text) !important;
}

.main-nowPlayingBar-right button,
.main-nowPlayingBar-extraControls button,
.main-nowPlayingBar-volumeBar button,
.main-nowPlayingBar-lyricsButton button {
    color: var(--spice-text) !important;
}

.main-nowPlayingBar-right svg,
.main-nowPlayingBar-extraControls svg,
.main-nowPlayingBar-volumeBar svg,
.main-nowPlayingBar-lyricsButton svg,
.main-connectBar-connectBar svg,
.main-connectBar-icon svg {
    fill: currentColor !important;
    color: var(--spice-text) !important;
}

/* Volume slider track + progress bar */
.main-nowPlayingBar-volumeBar .progress-bar__bg,
.progress-bar__bg {
    background-color: var(--spice-selected-row) !important;
}
.progress-bar__fg {
    background-color: var(--spice-text) !important;
}
EOF

# Apply. Requires /opt/spotify writable (`sudo chmod -R a+wr /opt/spotify`);
# without it spicetify prints a scary "fatal: permission denied". Suppress
# stdout too so target output stays clean — user sees green label only.
spicetify config current_theme Generated >/dev/null 2>&1
# Offline swap: only restart (and thus launch) Spotify when it's already
# running. When closed, patch with --no-restart so the new theme is staged for
# the next manual launch instead of popping Spotify open on every theme sync.
if pgrep -x spotify >/dev/null 2>&1; then
    spicetify apply >/dev/null 2>&1
else
    spicetify apply -n >/dev/null 2>&1
fi

# Detect missing perms so user gets an actionable hint instead of silence.
if [[ ! -w /opt/spotify/Apps/xpui.spa ]]; then
    echo -e "    ${GREEN}spotify (spicetify)${RESET} — config written; run 'sudo chmod -R a+wr /opt/spotify' to enable apply"
else
    echo -e "    ${GREEN}spotify (spicetify)${RESET}"
fi
