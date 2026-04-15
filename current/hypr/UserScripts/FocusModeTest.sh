#!/usr/bin/env bash
# Focus Mode Test Script — проверка всей функциональности

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0
WARN=0

pass() { echo -e "${GREEN}✓ PASS${NC}: $1"; ((PASS++)) || true; }
fail() { echo -e "${RED}✗ FAIL${NC}: $1"; ((FAIL++)) || true; }
warn() { echo -e "${YELLOW}⚠ WARN${NC}: $1"; ((WARN++)) || true; }
info() { echo -e "  INFO: $1"; }

echo "═══════════════════════════════════════════════════════"
echo "        Focus Mode Test Suite"
echo "═══════════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────────
echo "1. CHECKING FILES"
echo "─────────────────────────────────────────────────────────"

# Scripts
[ -x "$HOME/.config/hypr/UserScripts/FocusMode.sh" ] && \
    pass "FocusMode.sh exists and executable" || \
    fail "FocusMode.sh missing or not executable"

[ -x "$HOME/.config/hypr/UserScripts/FocusModeWatcher.sh" ] && \
    pass "FocusModeWatcher.sh exists and executable" || \
    fail "FocusModeWatcher.sh missing or not executable"

# Config files
[ -f "$HOME/.config/focus-mode/blocked-apps" ] && \
    pass "blocked-apps config exists" || \
    fail "blocked-apps config missing"

[ -f "$HOME/.config/focus-mode/blocked-sites" ] && \
    pass "blocked-sites config exists" || \
    fail "blocked-sites config missing"

# Keybind
grep -q "FocusMode.sh" "$HOME/.config/hypr/UserConfigs/UserKeybinds.conf" 2>/dev/null && \
    pass "Keybind configured in UserKeybinds.conf" || \
    fail "Keybind not found"

# Autostart
grep -q "FocusModeWatcher" "$HOME/.config/hypr/UserConfigs/Startup_Apps.conf" 2>/dev/null && \
    pass "Autostart configured in Startup_Apps.conf" || \
    fail "Autostart not found"

echo ""

# ─────────────────────────────────────────────────────────
echo "2. CHECKING DEPENDENCIES"
echo "─────────────────────────────────────────────────────────"

command -v socat &>/dev/null && \
    pass "socat installed" || \
    fail "socat NOT installed (required for IPC)"

command -v hyprctl &>/dev/null && \
    pass "hyprctl available" || \
    fail "hyprctl NOT available"

command -v swaync-client &>/dev/null && \
    pass "swaync-client available" || \
    warn "swaync-client NOT available (DND won't work)"

command -v notify-send &>/dev/null && \
    pass "notify-send available" || \
    warn "notify-send NOT available (notifications won't work)"

echo ""

# ─────────────────────────────────────────────────────────
echo "3. CHECKING SUDO PERMISSIONS"
echo "─────────────────────────────────────────────────────────"

# Test sudo for tee
if sudo -n mkdir -p /etc/opt/chrome/policies/managed 2>/dev/null; then
    pass "sudo mkdir (NOPASSWD) works"
else
    fail "sudo mkdir requires password — check /etc/sudoers.d/focus-mode"
    info "Expected: liker ALL=(ALL) NOPASSWD: /bin/mkdir -p /etc/opt/chrome/policies/managed"
fi

# Test sudo for tee (create temp file)
TEST_POLICY="/etc/opt/chrome/policies/managed/.focus-mode-test"
if echo "test" | sudo -n tee "$TEST_POLICY" &>/dev/null; then
    pass "sudo tee (NOPASSWD) works"
    sudo -n rm -f "$TEST_POLICY" 2>/dev/null
else
    fail "sudo tee requires password — check /etc/sudoers.d/focus-mode"
    info "Expected: liker ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/opt/chrome/policies/managed/focus-mode.json"
fi

echo ""

# ─────────────────────────────────────────────────────────
echo "4. CHECKING HYPRLAND IPC"
echo "─────────────────────────────────────────────────────────"

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    pass "HYPRLAND_INSTANCE_SIGNATURE set"
    SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    if [ -S "$SOCKET" ]; then
        pass "Hyprland IPC socket exists"
    else
        fail "Hyprland IPC socket NOT found: $SOCKET"
    fi
else
    fail "HYPRLAND_INSTANCE_SIGNATURE not set (not running in Hyprland?)"
fi

echo ""

# ─────────────────────────────────────────────────────────
echo "5. CHECKING CURRENT STATE"
echo "─────────────────────────────────────────────────────────"

STATE="$HOME/.config/focus-mode/state"
POLICY="/etc/opt/chrome/policies/managed/focus-mode.json"

if [ -f "$STATE" ]; then
    info "State file: EXISTS (Focus Mode ON)"
else
    info "State file: NOT EXISTS (Focus Mode OFF)"
fi

if [ -f "$POLICY" ]; then
    info "Chrome policy: EXISTS"
else
    info "Chrome policy: NOT EXISTS"
fi

if pgrep -f "FocusModeWatcher.sh" &>/dev/null; then
    info "Watcher process: RUNNING"
else
    info "Watcher process: NOT RUNNING"
fi

# Check sync
if [ -f "$STATE" ] && [ -f "$POLICY" ]; then
    pass "State synchronized (both exist)"
elif [ ! -f "$STATE" ] && [ ! -f "$POLICY" ]; then
    pass "State synchronized (both absent)"
else
    warn "State NOT synchronized (state=$([[ -f $STATE ]] && echo Y || echo N), policy=$([[ -f $POLICY ]] && echo Y || echo N))"
fi

echo ""

# ─────────────────────────────────────────────────────────
echo "6. SYNTAX CHECK"
echo "─────────────────────────────────────────────────────────"

bash -n "$HOME/.config/hypr/UserScripts/FocusMode.sh" 2>/dev/null && \
    pass "FocusMode.sh syntax OK" || \
    fail "FocusMode.sh syntax ERROR"

bash -n "$HOME/.config/hypr/UserScripts/FocusModeWatcher.sh" 2>/dev/null && \
    pass "FocusModeWatcher.sh syntax OK" || \
    fail "FocusModeWatcher.sh syntax ERROR"

echo ""

# ─────────────────────────────────────────────────────────
echo "7. CONFIG CONTENT"
echo "─────────────────────────────────────────────────────────"

APPS_COUNT=$(grep -cv '^#\|^$' "$HOME/.config/focus-mode/blocked-apps" 2>/dev/null || echo 0)
SITES_COUNT=$(grep -cv '^#\|^$' "$HOME/.config/focus-mode/blocked-sites" 2>/dev/null || echo 0)

info "Blocked apps: $APPS_COUNT"
info "Blocked sites: $SITES_COUNT"

[ "$APPS_COUNT" -gt 0 ] && pass "blocked-apps has entries" || warn "blocked-apps is empty"
[ "$SITES_COUNT" -gt 0 ] && pass "blocked-sites has entries" || warn "blocked-sites is empty"

echo ""

# ─────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════"
echo "        RESULTS"
echo "═══════════════════════════════════════════════════════"
echo ""
echo -e "  ${GREEN}PASS${NC}: $PASS"
echo -e "  ${RED}FAIL${NC}: $FAIL"
echo -e "  ${YELLOW}WARN${NC}: $WARN"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All critical checks passed!${NC}"
    echo ""
    echo "To test manually:"
    echo "  1. Press Super+Escape to toggle Focus Mode"
    echo "  2. Try opening discord/steam/telegram"
    echo "  3. Try opening youtube.com in Chrome"
    echo ""
else
    echo -e "${RED}Some checks failed. Fix issues above before using.${NC}"
    exit 1
fi
