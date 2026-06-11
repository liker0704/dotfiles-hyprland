#!/usr/bin/env bash
# Unified tmux session picker: live sessions + killed ones ("graveyard").
# Picking a live session switches to it. Picking a 💀 killed session revives it
# from its snapshot — recreating each window at its saved cwd — then switches.
# Snapshots are written by KillActiveProcess.sh (Win+Shift+Q): one line per
# window, "name|cwd". This is what makes Win+Shift+Q "kill but restartable":
# continuum's autosave drops the session from its restore file, the graveyard
# keeps it.

GRAVE="$HOME/.local/state/tmux/graveyard"

revive() {
    local name=$1 f="$GRAVE/$1" first=1 wname cwd
    if [[ -s "$f" ]]; then
        while IFS='|' read -r wname cwd; do
            [[ -z "$cwd" || ! -d "$cwd" ]] && cwd="$HOME"
            if (( first )); then
                tmux new-session -d -s "$name" -c "$cwd" -n "$wname"
                first=0
            else
                tmux new-window -t "$name:" -c "$cwd" -n "$wname"
            fi
        done < "$f"
    fi
    (( first )) && tmux new-session -d -s "$name" -c "$HOME"
    rm -f "$f"
}

live=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

killed=""
if [[ -d "$GRAVE" ]]; then
    while IFS= read -r f; do
        name=$(basename "$f")
        grep -qxF "$name" <<<"$live" || killed+="💀 $name"$'\n'
    done < <(find "$GRAVE" -maxdepth 1 -type f 2>/dev/null)
fi

sel=$(printf '%s\n%s' "$live" "$killed" | sed '/^$/d' \
        | fzf --reverse --prompt 'session> ')
[[ -z "$sel" ]] && exit 0

if [[ "$sel" == 💀\ * ]]; then
    name=${sel#💀 }
    revive "$name"
else
    name=$sel
fi

tmux switch-client -t "$name" 2>/dev/null || tmux attach -t "$name"
