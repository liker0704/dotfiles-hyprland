# Rofi application launcher

local ROFI_THEME="$HOME/.config/rofi/themes/Monochrome-Dark.rasi"
if [[ -f "$ROFI_THEME" ]]; then
  sed -i \
    -e 's/^\(    background: *\)#[^;]*/\1#'"${C[bg]}"'/' \
    -e 's/^\(    background-alt: *\)#[^;]*/\1#'"${C[bg_light]}"'/' \
    -e 's/^\(    foreground: *\)#[^;]*/\1#'"${C[fg]}"'/' \
    -e 's/^\(    selected: *\)#[^;]*/\1#'"${accent}"'/' \
    -e 's/^\(    active: *\)#[^;]*/\1#'"${C[fg_dim]}"'/' \
    -e 's/^\(    urgent: *\)#[^;]*/\1#'"${C[red]}"'/' \
    -e 's/^\(    border-dim: *\)#[^;]*/\1#'"${C[border]}"'/' \
    -e 's/^\(    text-dim: *\)#[^;]*/\1#'"${C[fg_muted]}"'/' \
    "$ROFI_THEME"
  echo -e "    ${GREEN}rofi${RESET}"
fi
