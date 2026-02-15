# SwayNC notification center

local SWAYNC_STYLE="$HOME/.config/swaync/style.css"
if [[ -f "$SWAYNC_STYLE" ]]; then
  sed -i \
    -e 's|^\(@define-color noti-border-color \)#[^;]*|\1#'"${C[border]}"'|' \
    -e 's|^\(@define-color noti-bg \)#[^;]*|\1#'"${C[bg]}"'|' \
    -e 's|^\(@define-color noti-bg-alt \)#[^;]*|\1#'"${C[bg_light]}"'|' \
    -e 's|^\(@define-color noti-bg-hover \)#[^;]*|\1#'"${C[bg_light]}"'|' \
    -e 's|^\(@define-color text-color \)#[^;]*|\1#'"${C[fg]}"'|' \
    -e 's|^\(@define-color accent \)#[^;]*|\1#'"${accent}"'|' \
    -e 's|^\(@define-color text-dim \)#[^;]*|\1#'"${C[fg_muted]}"'|' \
    -e 's|^\(@define-color urgent \)#[^;]*|\1#'"${C[red]}"'|' \
    "$SWAYNC_STYLE"
  echo -e "    ${GREEN}swaync${RESET}"
fi
