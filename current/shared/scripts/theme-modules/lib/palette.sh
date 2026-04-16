# Read palette.conf into associative array C[] and derived variables
# After sourcing: C[], FONT, is_light, accent, shadow are available

read_palette() {
  if [[ ! -f "$PALETTE" ]]; then
    echo -e "${RED}Palette not found: $PALETTE${RESET}"
    exit 1
  fi

  declare -gA C
  while IFS='=' read -r key val; do
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    key=$(echo "$key" | xargs); val=$(echo "$val" | xargs)
    [[ -n "$key" && -n "$val" ]] && C[$key]="$val"
  done < "$PALETTE"

  # Font
  FONT=$(grep '^font=' "$PALETTE" 2>/dev/null | cut -d= -f2-)
  [[ -z "$FONT" ]] && FONT="JetBrainsMono Nerd Font"

  # Detect dark/light: full-image Lab L mean via theme-detect-mode helper
  # (more robust than single-pixel BT.601 on wallust bg). Falls back to
  # bg-based BT.601 if detector unavailable.
  is_light=false
  if command -v theme-detect-mode &>/dev/null; then
    [[ "$(theme-detect-mode)" == "light" ]] && is_light=true
  else
    local bg_r=$((16#${C[bg]:0:2})) bg_g=$((16#${C[bg]:2:2})) bg_b=$((16#${C[bg]:4:2}))
    local bg_lum=$(( (bg_r * 299 + bg_g * 587 + bg_b * 114) / 1000 ))
    (( bg_lum > 128 )) && is_light=true
  fi

  # Accent & shadow
  if $is_light; then
    local bk_r=$((16#${C[black]:0:2})) bk_g=$((16#${C[black]:2:2})) bk_b=$((16#${C[black]:4:2}))
    local bk_lum=$(( (bk_r * 299 + bk_g * 587 + bk_b * 114) / 1000 ))
    if (( bk_lum > 128 )); then
      accent="${C[white]}"
    else
      accent="${C[black]}"
    fi
    shadow="rgba(0, 0, 0, 0.08)"
  else
    accent="${C[bright_white]}"
    shadow="rgba(0, 0, 0, 0.3)"
  fi
}
