#!/usr/bin/env bash
# Win+Shift+Q — force-kill the active window's process.
#
# Special case: if the active window is a terminal hosting a tmux client,
# kill that tmux session first so the server doesn't keep it alive in the
# background after the window dies. Continuum auto-saves every 5 minutes
# and restores on next tmux launch, so state isn't lost.
#
# For non-terminal apps (browser, editor, etc.) we skip the tmux walk
# entirely — no point scanning a Zen/Obsidian process tree.

readonly TERMINAL_CLASSES_REGEX='^(kitty|Alacritty|foot|WezTerm|wezterm|org\.wezfurlong\.wezterm)$'

active=$(hyprctl activewindow -j 2>/dev/null)
[[ -z "$active" ]] && exit 0

active_pid=$(printf '%s' "$active" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("pid",""))' 2>/dev/null)
active_class=$(printf '%s' "$active" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("class",""))' 2>/dev/null)
[[ -z "$active_pid" ]] && exit 0

find_tmux_client() {
    local pid=$1
    local cmd
    cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
    # tmux client sets comm via prctl to "tmux: client", server to "tmux: server"
    if [[ "$cmd" == tmux* ]]; then
        echo "$pid"
        return
    fi
    local child
    for child in $(pgrep -P "$pid" 2>/dev/null); do
        local found
        found=$(find_tmux_client "$child")
        if [[ -n "$found" ]]; then
            echo "$found"
            return
        fi
    done
}

if [[ "$active_class" =~ $TERMINAL_CLASSES_REGEX ]]; then
    tmux_client_pid=$(find_tmux_client "$active_pid")
    if [[ -n "$tmux_client_pid" ]]; then
        session_id=$(tmux list-clients -F '#{client_pid} #{session_id}' 2>/dev/null \
            | awk -v p="$tmux_client_pid" '$1 == p { print $2; exit }')
        if [[ -n "$session_id" ]]; then
            # Snapshot the session before killing so it can be revived later.
            # continuum's 5-min autosave would otherwise drop the killed session
            # from its restore file, making it unrecoverable. One line per
            # window: "name|cwd". Revive via the session picker (Alt+S) — killed
            # sessions show with a 💀 marker.
            session_name=$(tmux display-message -p -t "$session_id" '#{session_name}' 2>/dev/null)
            if [[ -n "$session_name" ]]; then
                grave="$HOME/.local/state/tmux/graveyard"
                mkdir -p "$grave"
                tmux list-windows -t "$session_id" \
                    -F '#{window_name}|#{pane_current_path}' 2>/dev/null \
                    > "$grave/$session_name"
            fi
            tmux kill-session -t "$session_id" 2>/dev/null
        fi
    fi
fi

kill "$active_pid"
