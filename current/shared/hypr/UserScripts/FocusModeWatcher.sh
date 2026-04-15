#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Focus Mode Watcher - Monitors and blocks distracting applications

STATE="$HOME/.config/focus-mode/state"
CONFIG="$HOME/.config/focus-mode/blocked-apps"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
LOGFILE="$HOME/.config/focus-mode/watcher.log"

log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOGFILE"; }

# Array to store blocked apps
declare -a BLOCKED_APPS

# Load blocked apps from config file
load_blocked_apps() {
    BLOCKED_APPS=()

    if [ ! -f "$CONFIG" ]; then
        log "Warning: Config file not found: $CONFIG"
        return 1
    fi

    while IFS= read -r app || [ -n "$app" ]; do
        # Skip empty lines and comments
        [[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
        # Trim whitespace and convert to lowercase
        app=$(echo "$app" | xargs)
        app="${app,,}"
        [ -n "$app" ] && BLOCKED_APPS+=("$app")
    done < "$CONFIG"

    log "Loaded ${#BLOCKED_APPS[@]} blocked apps"
}

# Check if a window class is in the blocked list (partial match for Flatpak support)
# Returns blocked app name via MATCHED_APP variable
is_blocked() {
    local class="$1"
    local class_lower="${class,,}"  # bash lowercase
    MATCHED_APP=""

    for blocked in "${BLOCKED_APPS[@]}"; do
        # Partial match: org.telegram.desktop matches "telegram"
        if [[ "$class_lower" == *"$blocked"* ]]; then
            MATCHED_APP="$blocked"
            return 0
        fi
    done
    return 1
}

# Check preconditions
check_environment() {
    # Check if focus mode is active
    if [ ! -f "$STATE" ]; then
        log "Focus mode not active, exiting"
        exit 0
    fi

    # Check if Hyprland is running
    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        log "Error: HYPRLAND_INSTANCE_SIGNATURE not set"
        exit 1
    fi

    # Check if socket exists
    if [ ! -S "$SOCKET" ]; then
        log "Error: Hyprland IPC socket not found: $SOCKET"
        exit 1
    fi
}

# Main function
main() {
    check_environment
    load_blocked_apps

    log "Watcher started"

    # Monitor Hyprland IPC events
    socat -U - UNIX-CONNECT:"$SOCKET" 2>/dev/null | while read -r line; do
        # Check if focus mode is still active (exit if not)
        if [ ! -f "$STATE" ]; then
            log "Focus mode deactivated, exiting"
            exit 0
        fi

        # Parse openwindow events
        # Format: openwindow>>ADDRESS,WORKSPACE,CLASS,TITLE
        if [[ "$line" == openwindow* ]]; then
            # Remove "openwindow>>" prefix
            event_data="${line#openwindow>>}"

            # Split by comma
            IFS=',' read -r address workspace class title <<< "$event_data"

            # Check if this app is blocked
            if is_blocked "$class"; then
                log "Blocked: $class (matched: $MATCHED_APP)"

                # Kill the process using matched app name (not class - for Flatpak)
                pkill -i "$MATCHED_APP" 2>/dev/null || hyprctl dispatch closewindow "address:$address" >/dev/null 2>&1

                # Show notification
                notify-send "Focus Mode" "Blocked: $MATCHED_APP" -u critical -t 3000
            fi
        fi
    done
}

# Run main function
main
