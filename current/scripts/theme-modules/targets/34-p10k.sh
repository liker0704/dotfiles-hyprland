# Powerlevel10k ZSH prompt

local P10K_CONF="$HOME/.p10k.zsh"
if [[ -f "$P10K_CONF" ]]; then
  sed -i \
    -e "s|\(POWERLEVEL9K_BACKGROUND=\).*|\1'#${C[bg_light]}'|" \
    -e "s|\(POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=\).*|\1'#${C[border]}'|" \
    -e "s|\(POWERLEVEL9K_DIR_FOREGROUND=\).*|\1'#${C[blue]}'|" \
    -e "s|\(POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=\).*|\1'#${C[fg_muted]}'|" \
    -e "s|\(POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=\).*|\1'#${C[cyan]}'|" \
    -e "s|\(POWERLEVEL9K_VCS_CLEAN_FOREGROUND=\).*|\1'#${C[green]}'|" \
    -e "s|\(POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=\).*|\1'#${C[green]}'|" \
    -e "s|\(POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=\).*|\1'#${C[yellow]}'|" \
    "$P10K_CONF"
  echo -e "    ${GREEN}p10k${RESET}"
fi
