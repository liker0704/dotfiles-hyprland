# --- tmux auto-start (MUST BE FIRST) ---
if [[ -z "$TMUX" && -z "$NOTERM" && -t 1 ]]; then
    # Heal stale server contaminated by the assistant container:
    # container's `bun` user has SHELL="" and /etc/passwd shell=/bin/sh, so any
    # `tmux new-session` from the container before the host server exists creates
    # a server with default-shell=/bin/sh. Force-reset the option, then respawn
    # any pane stuck in sh (preserves session history vs. kill-session).
    if tmux has-session 2>/dev/null; then
        tmux set-option -g default-shell /usr/bin/zsh 2>/dev/null
        tmux set-option -g default-command /usr/bin/zsh 2>/dev/null
        tmux list-panes -aF '#{pane_id} #{pane_current_command}' 2>/dev/null \
            | awk '$2 == "sh" { print $1 }' \
            | while read -r pane; do
                tmux respawn-pane -k -t "$pane" /usr/bin/zsh 2>/dev/null
              done
    fi
    exec tmux new-session -A -s main
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -------------------------------------------------------------------
# ### БЛОК ЗАГРУЗКИ OH MY ZSH (ОБЯЗАТЕЛЕН) ###
# -------------------------------------------------------------------

# Путь к установке Oh My Zsh.
export ZSH="$HOME/.oh-my-zsh"

# Disable insecure directory warning (we trust these completions)
ZSH_DISABLE_COMPFIX=true

# Здесь указывается тема.
ZSH_THEME="powerlevel10k/powerlevel10k"

# Здесь указываются плагины (через пробел).
# syntax-highlighting ДОЛЖЕН быть последним!
plugins=(git zsh-autosuggestions)

# --- Оптимизация autosuggestions ---
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
DISABLE_MAGIC_FUNCTIONS=true

# ЭТА СТРОКА - САМАЯ ГЛАВНАЯ. Она запускает Oh My Zsh.
# Она должна идти ПОСЛЕ ZSH_THEME и plugins.
source $ZSH/oh-my-zsh.sh

# Отключить подсветку при вставке текста
zle_highlight+=(paste:none)

# -------------------------------------------------------------------
# ### ТВОИ ПЕРСОНАЛЬНЫЕ НАСТРОЙКИ (ИДУТ ПОСЛЕ ЗАГРУЗКИ OH MY ZSH) ###
# -------------------------------------------------------------------

# --- Android SDK ---
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# --- NVM (Node Version Manager) ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# --- SDKMAN ---
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# --- Локальные скрипты пользователя ---
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

# --- Полезные алиасы (псевдонимы) ---
alias ls='ls --color=auto'
# alias ll='ls -l'
# alias la='ls -A'

# --- Theme wrapper (reload p10k after theme changes) ---
theme() {
  command theme "$@"
  local rc=$?
  [[ "$1" =~ ^(set|random|generate|font|sync)$ ]] && source ~/.p10k.zsh 2>/dev/null
  return $rc
}


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Use native Claude Code binary
claude() {
  command "$HOME/.local/bin/claude" "$@"
}

# Claude Code alias with auto-skip permissions
alias cc="claude --dangerously-skip-permissions"

alias ge="gemini --yolo"


alias nv="nvim"
alias tm="tmux attach -t main || tmux new-session -s main"

# Yazi wrapper - changes dir on exit (q), stays in place on Q
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
	rm -f -- "$tmp"
}


# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Go binaries
export PATH="$PATH:$HOME/go/bin"

# User scripts
export PATH="$PATH:$HOME/scripts"


alias cod='codex --dangerously-bypass-approvals-and-sandbox'

# Dedupe PATH (zshrc may be sourced twice via tmux/exec chains)
typeset -U path PATH

# Default browser for CLI tools (NordVPN login, gh, etc.)
export BROWSER=/usr/bin/zen-browser

# Machine-specific overrides (not in git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
