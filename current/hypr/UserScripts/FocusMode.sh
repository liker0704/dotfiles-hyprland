#!/usr/bin/env bash
# Focus Mode Toggle Script
# Blocks distracting sites via /etc/hosts (works in ALL browsers: Chrome, Zen, Firefox)
# Also applies Chrome policy for extra enforcement

STATE="$HOME/.config/focus-mode/state"
CONFIG_DIR="$HOME/.config/focus-mode"
SCRIPT_DIR="$HOME/.config/hypr/UserScripts"
BLOCKED_APPS="$CONFIG_DIR/blocked-apps"
BLOCKED_SITES="$CONFIG_DIR/blocked-sites"
HOSTS_MARKER="# FOCUS-MODE-BLOCK"
HELPER="sudo /usr/local/bin/focus-mode-helper"
ZEN_FOCUS_DIR="/tmp/zen-focus"
ZEN_STATE_JSON="$ZEN_FOCUS_DIR/state.json"
ZEN_SERVER_PID="$ZEN_FOCUS_DIR/server.pid"

# Write state.json for Zen extension
write_state_json() {
    local active="$1"
    mkdir -p "$ZEN_FOCUS_DIR"
    local sites_json="[]"
    if [ -f "$BLOCKED_SITES" ]; then
        sites_json=$(while IFS= read -r site || [ -n "$site" ]; do
            [[ -z "$site" || "$site" =~ ^[[:space:]]*# ]] && continue
            echo "$site" | xargs
        done < "$BLOCKED_SITES" | jq -R . | jq -s .)
    fi
    jq -n --argjson active "$active" --argjson sites "$sites_json" \
        '{active: $active, sites: $sites}' > "$ZEN_STATE_JSON"
}

# Start HTTP server for Zen extension
start_zen_server() {
    # Kill existing server if running
    stop_zen_server 2>/dev/null
    "$HOME/.local/bin/focus-mode-server" &>/dev/null &
    disown
}

# Stop HTTP server
stop_zen_server() {
    if [ -f "$ZEN_SERVER_PID" ]; then
        local pid
        pid=$(cat "$ZEN_SERVER_PID" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
        fi
        rm -f "$ZEN_SERVER_PID"
    fi
    # Fallback: kill by port
    pkill -f "focus-mode-server" 2>/dev/null || true
}

# Kill blocked app processes
kill_blocked_apps() {
    [ ! -f "$BLOCKED_APPS" ] && return

    while IFS= read -r app || [ -n "$app" ]; do
        [[ -z "$app" || "$app" =~ ^[[:space:]]*# ]] && continue
        app=$(echo "$app" | xargs)
        if pgrep -i "$app" &>/dev/null; then
            pkill -i "$app" 2>/dev/null || true
            notify-send "Focus Mode" "Killed: $app" -u normal -t 2000
        fi
    done < "$BLOCKED_APPS"
}

# Block sites via /etc/hosts (works for ALL browsers)
block_hosts() {
    [ ! -f "$BLOCKED_SITES" ] && return

    # Skip if already blocked
    grep -q "$HOSTS_MARKER" /etc/hosts 2>/dev/null && return

    local entries=""
    while IFS= read -r site || [ -n "$site" ]; do
        [[ -z "$site" || "$site" =~ ^[[:space:]]*# ]] && continue
        site=$(echo "$site" | xargs)
        entries+="127.0.0.1 ${site} ${HOSTS_MARKER}\n"
        entries+="127.0.0.1 www.${site} ${HOSTS_MARKER}\n"
        entries+="::1 ${site} ${HOSTS_MARKER}\n"
        entries+="::1 www.${site} ${HOSTS_MARKER}\n"
    done < "$BLOCKED_SITES"

    echo -e "$entries" | $HELPER block-hosts
}

# Unblock sites from /etc/hosts
unblock_hosts() {
    $HELPER unblock-hosts
}

# Generate Chrome Policy JSON (keep for Chrome compatibility)
generate_chrome_policy() {
    local url_list=""
    if [ -f "$BLOCKED_SITES" ]; then
        while IFS= read -r site || [ -n "$site" ]; do
            [[ -z "$site" || "$site" =~ ^[[:space:]]*# ]] && continue
            site=$(echo "$site" | xargs)
            url_list+="\"${site}\", "
        done < "$BLOCKED_SITES"
        url_list="${url_list%, }"
    fi
    cat <<EOF
{
  "URLBlocklist": [$url_list],
  "DnsOverHttpsMode": "off"
}
EOF
}

# Enable Focus Mode
enable_focus_mode() {
    touch "$STATE"

    notify-send "Focus Mode" "ON - distractions blocked" -u normal -t 5000
    sleep 1

    # Enable DND
    swaync-client --dnd-on

    # Zen extension: write state + start server
    write_state_json true
    start_zen_server

    # Block sites via /etc/hosts (fallback for Chrome)
    block_hosts

    # Chrome policy (extra layer for Chrome)
    local policy_json=$(generate_chrome_policy)
    echo "$policy_json" | $HELPER set-chrome-policy

    # Reload Chrome if running
    if pgrep -f chrome &>/dev/null; then
        chrome_geo=$(hyprctl clients -j | jq -r '.[] | select(.class == "google-chrome") | "\(.at[0]),\(.at[1]),\(.size[0]),\(.size[1]),\(.workspace.id)"' | head -1)
        pkill -f chrome
        sleep 1
        "$HOME/.local/bin/google-chrome" &>/dev/null &
        if [ -n "$chrome_geo" ]; then
            for i in {1..100}; do
                hyprctl clients -j | jq -e '.[] | select(.class == "google-chrome")' &>/dev/null && break
                sleep 0.1
            done
            IFS=',' read -r x y w h ws <<< "$chrome_geo"
            hyprctl dispatch movetoworkspacesilent "$ws,class:google-chrome" &>/dev/null
            hyprctl dispatch movewindowpixel "exact $x $y,class:google-chrome" &>/dev/null
            hyprctl dispatch resizewindowpixel "exact $w $h,class:google-chrome" &>/dev/null
        fi
    fi

    kill_blocked_apps

    # Start watcher
    pkill -f "FocusModeWatcher.sh" 2>/dev/null || true
    "$SCRIPT_DIR/FocusModeWatcher.sh" &
}

# Disable Focus Mode
disable_focus_mode() {
    rm -f "$STATE"

    swaync-client --dnd-off

    # Zen extension: write inactive state, delay server stop
    write_state_json false
    (sleep 5 && stop_zen_server) &>/dev/null &
    disown

    # Unblock sites from /etc/hosts
    unblock_hosts

    # Flush DNS cache so browsers pick up changes immediately
    resolvectl flush-caches 2>/dev/null || true

    # Remove Chrome policy
    $HELPER remove-chrome-policy

    # Stop watcher
    pkill -f "FocusModeWatcher.sh" || true

    notify-send "Focus Mode" "OFF" -u normal -t 5000
}

# Main
if [ -f "$STATE" ]; then
    disable_focus_mode
else
    enable_focus_mode
fi

exit 0
