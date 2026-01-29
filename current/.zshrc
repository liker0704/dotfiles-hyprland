# --- Zellij auto-start (MUST BE FIRST) ---
if [[ -z "$ZELLIJ" && -t 1 ]]; then
    exec zellij attach -c main
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
plugins=(git zsh-autosuggestions fast-syntax-highlighting)

# --- Оптимизация для устранения подёргивания курсора ---
ZSH_HIGHLIGHT_MAXLENGTH=512
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
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
export PATH=$PATH:/home/liker/progs/android-studio/bin

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
# Установка unfree пакетов: nix-install spotify
nix-install() {
  NIXPKGS_ALLOW_UNFREE=1 nix profile install "nixpkgs#$1" --impure
}
# alias ll='ls -l'
# alias la='ls -A'

# --- Conda Initialize ---
# !! Блок Conda всегда должен быть в конце !!
__conda_setup="$('/home/liker/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/liker/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/liker/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/liker/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Claude Code alias with auto-skip permissions
alias cc="claude --dangerously-skip-permissions"

alias ge="gemini --yolo"


alias nv="nvim"
alias zj="zellij attach -c main"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# bun completions
[ -s "/home/liker/.bun/_bun" ] && source "/home/liker/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Go binaries
export PATH="$PATH:$HOME/go/bin"

