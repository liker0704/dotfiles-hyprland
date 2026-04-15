# Claude Code theme (ANSI = follows terminal palette)

local CLAUDE_JSON="$HOME/.claude.json"
if [[ -f "$CLAUDE_JSON" ]]; then
  # Ensure tweakcc patches are applied (ANSI themes require it)
  local CC_DIR="$HOME/.local/share/claude"
  if [[ -d "$CC_DIR" ]] && command -v npx &>/dev/null; then
    local CC_VER; CC_VER=$(ls -1 "$CC_DIR/versions/" 2>/dev/null | sort -V | tail -1)
    local TWEAKCC_VER; TWEAKCC_VER=$(python3 -c "
import json
with open('$HOME/.tweakcc/config.json') as f: print(json.load(f).get('ccVersion',''))
" 2>/dev/null)
    if [[ -n "$CC_VER" && "$CC_VER" != "$TWEAKCC_VER" ]]; then
      echo -e "  ${DIM}Patching Claude Code $CC_VER with tweakcc...${RESET}"
      npx tweakcc --apply &>/dev/null
    fi
  fi
  local cc_theme; cc_theme=$($is_light && echo "light-ansi" || echo "dark-ansi")
  python3 -c "
import json
with open('$CLAUDE_JSON') as f: d = json.load(f)
d['theme'] = '$cc_theme'
with open('$CLAUDE_JSON', 'w') as f: json.dump(d, f, indent=2)
" 2>/dev/null
fi
echo -e "    ${GREEN}claude${RESET}"
