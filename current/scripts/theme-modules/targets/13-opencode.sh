# OpenCode TUI theme

local OC_DIR="$HOME/.config/opencode"
local OC_THEMES="$OC_DIR/themes"
local OC_TUI="$OC_DIR/tui.json"

mkdir -p "$OC_THEMES"

cat > "$OC_THEMES/palette.json" << EOF
{
  "\$schema": "https://opencode.ai/theme.json",
  "theme": {
    "primary": "#${C[bright_cyan]}",
    "secondary": "#${C[bright_blue]}",
    "accent": "#${C[bright_magenta]}",
    "error": "#${C[red]}",
    "warning": "#${C[yellow]}",
    "success": "#${C[green]}",
    "info": "#${C[blue]}",

    "text": "#${C[fg]}",
    "textMuted": "#${C[fg_muted]}",
    "background": "#${C[bg]}",
    "backgroundPanel": "#${C[bg_light]}",
    "backgroundElement": "#${C[bg_highlight]}",

    "border": "#${C[border]}",
    "borderActive": "#${C[fg_dim]}",
    "borderSubtle": "#${C[bg_highlight]}",

    "diffAdded": "#${C[green]}",
    "diffRemoved": "#${C[red]}",
    "diffContext": "#${C[fg_muted]}",
    "diffHunkHeader": "#${C[bright_blue]}",
    "diffHighlightAdded": "#${C[bright_green]}",
    "diffHighlightRemoved": "#${C[bright_red]}",

    "syntaxComment": "#${C[bright_black]}",
    "syntaxKeyword": "#${C[magenta]}",
    "syntaxFunction": "#${C[blue]}",
    "syntaxVariable": "#${C[fg]}",
    "syntaxString": "#${C[green]}",
    "syntaxNumber": "#${C[bright_magenta]}",
    "syntaxType": "#${C[yellow]}",
    "syntaxOperator": "#${C[cyan]}",
    "syntaxPunctuation": "#${C[fg_dim]}",

    "markdownHeading": "#${C[bright_blue]}",
    "markdownLink": "#${C[blue]}",
    "markdownCode": "#${C[bright_green]}",
    "markdownBlockQuote": "#${C[fg_dim]}",
    "markdownEmph": "#${C[bright_yellow]}",
    "markdownStrong": "#${C[bright_white]}",

    "inputBackground": "#${C[bg_light]}",
    "inputBorder": "#${C[border]}",
    "inputBorderActive": "#${C[bright_cyan]}",
    "inputCursor": "#${C[cursor]}",
    "inputText": "#${C[fg]}"
  }
}
EOF

# Update tui.json — set theme to "palette", preserve other keys
if [[ -f "$OC_TUI" ]]; then
  python3 -c "
import json
with open('$OC_TUI') as f: d = json.load(f)
d['theme'] = 'palette'
with open('$OC_TUI', 'w') as f: json.dump(d, f, indent=2)
" 2>/dev/null
else
  cat > "$OC_TUI" << 'TUIEOF'
{
  "$schema": "https://opencode.ai/tui.json",
  "theme": "palette"
}
TUIEOF
fi

echo -e "    ${GREEN}opencode${RESET}"
