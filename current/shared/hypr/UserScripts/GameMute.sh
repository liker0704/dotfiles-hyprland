#!/usr/bin/env bash
# Mute audio from gamescope games when window loses focus.

GAME_CLASS="gamescope"
MUTED=false

get_game_sink_inputs() {
    # Get the most recent gamescope PID (highest PID = newest)
    local gs_pid
    gs_pid=$(pgrep -f "^gamescope " | sort -rn | head -1)
    [ -z "$gs_pid" ] && return

    # Collect all descendant PIDs
    local all_pids="$gs_pid"
    local new_pids="$gs_pid"
    while [ -n "$new_pids" ]; do
        new_pids=$(ps -eo pid=,ppid= 2>/dev/null | awk -v pids="$new_pids" '
            BEGIN { split(pids, a, "\n"); for(i in a) p[a[i]]=1 }
            { if(p[$2] && !p[$1]) print $1 }
        ')
        [ -z "$new_pids" ] && break
        all_pids="$all_pids
$new_pids"
    done

    # Match sink-inputs whose PID is a gamescope descendant
    pactl list sink-inputs 2>/dev/null | awk '
        /Sink Input #/ { idx = $NF; gsub(/#/, "", idx) }
        /application.process.id/ {
            gsub(/.*= "/, ""); gsub(/"/, "")
            print idx ":" $0
        }
    ' | while IFS=: read -r idx pid; do
        echo "$all_pids" | grep -qw "$pid" && echo "$idx"
    done
}

set_mute() {
    local state="$1"
    local found=false
    for idx in $(get_game_sink_inputs); do
        pactl set-sink-input-mute "$idx" "$state" 2>/dev/null
        found=true
    done
    $found
}

mute_game() {
    [ "$MUTED" = true ] && return
    set_mute 1 && MUTED=true
}

unmute_game() {
    [ "$MUTED" = false ] && return
    set_mute 0 && MUTED=false
}

cleanup() {
    MUTED=true
    unmute_game
    exit 0
}
trap cleanup EXIT INT TERM

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - "UNIX-CONNECT:$SOCKET" | while IFS= read -r line; do
    case "$line" in
        activewindowv2*)
            addr="${line#*>>}"
            if [ -z "$addr" ]; then
                mute_game
                continue
            fi
            class=$(hyprctl clients -j | jq -r ".[] | select(.address == \"0x${addr}\") | .class")
            if [ "$class" = "$GAME_CLASS" ]; then
                unmute_game
            else
                mute_game
            fi
            ;;
    esac
done
