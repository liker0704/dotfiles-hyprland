# Web Research Report: Community Patterns

**Focus**: VNC keyboard forwarding / Super key passthrough with Hyprland (both ends Wayland)
**Status**: COMPLETE

---

## Findings

### Finding 1: TigerVNC fullscreen mode grabs keyboard and forwards Super key
**Quote**: "Automatically grab all input from the keyboard when entering full-screen and pass special keys (like Alt+Tab) directly to the server."
**Source**: https://tigervnc.org/doc/vncviewer.html
**Date**: Current docs
**Confidence**: High (90%)
**Practical insight**: The `-FullscreenSystemKeys` option (enabled by default in fullscreen) is the simplest fix. Switch vncviewer to fullscreen. The shortcut `Ctrl+Alt+G` manually grabs the keyboard in windowed mode, and `Ctrl+Alt+U` releases it. This is the first thing to try — it has no Hyprland config changes required.

The shortcut for manual grab toggle:
- `Ctrl+Alt+G` — grab keyboard (all keys forwarded to remote, including Super)
- `Ctrl+Alt+U` — release grab (local compositor gets keys back)

### Finding 2: The real root cause on Wayland — no global keyboard grab API
**Quote**: "Wayland does not expose API to grab/trap global keyboard input, and when you choose to use Wayland, you have to face these limitations."
**Source**: https://github.com/rustdesk/rustdesk/issues/13013
**Date**: 2025
**Confidence**: High (95%)
**Practical insight**: This is a fundamental Wayland architectural limitation. The compositor (local Hyprland) owns all input and decides what to forward. VNC clients running under Xwayland have even less ability to grab keys globally. This is why the issue exists across all remote desktop tools on Wayland (RustDesk, wayvnc, etc.), not just TigerVNC.

### Finding 3: Wayland keyboard-shortcuts-inhibit protocol is the proper fix
**Quote**: "A keyboard shortcuts inhibitor instructs the compositor to ignore its own keyboard shortcuts when the associated surface has keyboard focus, so the surface will receive all key events originating from the specified seat, even those which would normally be caught by the compositor for its own shortcuts."
**Source**: https://wayland.app/protocols/keyboard-shortcuts-inhibit-unstable-v1
**Date**: Protocol spec (stable)
**Confidence**: High (90%)
**Practical insight**: The `zwp_keyboard_shortcuts_inhibit_manager_v1` Wayland protocol is the "correct" solution. An application requests this, the compositor grants it, and the app gets all keys including Super. RustDesk implemented this in PR #14302 (merged Feb 2026). TigerVNC running under Xwayland cannot use this protocol directly since it is an X11 app. Wayland-native clients (e.g., a future native vncviewer port) could use it.

### Finding 4: Hyprland submap "passthru" / clean mode — manual toggle on LOCAL machine
**Quote**: "bind = MOD,KEY,submap,clean ... submap = clean ... bind = MOD,KEY,submap,reset"
**Source**: https://wiki.hypr.land/Configuring/Uncommon-tips--tricks/ (via search summary)
**Date**: Current wiki
**Confidence**: High (85%)
**Practical insight**: You can add a keybind to LOCAL Hyprland that enters a submap where almost no binds are defined. In this mode, key events are not consumed by local Hyprland and fall through to the focused window (the VNC viewer), which forwards them to the remote. This is the most reliable Hyprland-side workaround. Example config:

```ini
# In local Hyprland config
bind = SUPER, F12, submap, passthru

submap = passthru
# Only define the escape hatch — everything else falls through
bind = SUPER, F12, submap, reset
submap = reset
```

Press `Super+F12` to enter passthru mode. All subsequent keypresses (including Super combos) go to the focused window. Press `Super+F12` again to return to normal.

**Note**: One user in Hyprland Discussion #974 reported that a submap for passthrough "did not help" with wayvnc modifier keys — this was a separate wayvnc bug that was fixed in a commit. The submap approach should work for the LOCAL compositor side.

### Finding 5: Toggle script from Omarchy community (bash + hyprctl)
**Quote**:
```bash
SUBMAP_NAME="${1:-REMOTE_DESKTOP_KEYS}"
STATE_FILE="$HOME/.local/state/omarchy/toggles/remote-shortcuts"
if [[ -f "$STATE_FILE" ]]; then
  hyprctl dispatch submap reset >/dev/null 2>&1
  rm -f "$STATE_FILE"
else
  hyprctl dispatch submap "$SUBMAP_NAME" >/dev/null 2>&1
  : > "$STATE_FILE"
fi
```
**Source**: https://github.com/basecamp/omarchy/discussions/3105
**Date**: 2025
**Confidence**: High (85%)
**Practical insight**: A cleaner toggle script approach. Bind `Super+F12` to this script. The submap in hyprland.conf only needs the single exit binding — all other keys pass through to the focused VNC window. State file tracks on/off so the same key toggles both ways.

### Finding 6: RustDesk implemented keyboard-shortcuts-inhibit — most polished current solution
**Quote**: "Prevents the local compositor from intercepting keybindings when RustDesk is in focus during a remote session. Compatibility: Works with all major Wayland compositors that support the protocol. Status: Already implemented and merged (as of February 2026)"
**Source**: https://github.com/rustdesk/rustdesk/issues/13013 (PR #14302)
**Date**: February 2026
**Confidence**: High (85%)
**Practical insight**: If you are open to switching remote desktop tools, RustDesk (self-hosted) now handles this automatically on Wayland — no manual submap toggle needed. The client tells Hyprland to stop grabbing shortcuts while it is focused.

### Finding 7: Sunshine + Moonlight as an alternative with better key handling
**Quote**: "Sunshine is confirmed to work on Hyprland using KMS capture, offering a more reliable alternative... full device capture and audio working out of the box"
**Source**: https://forum.hypr.land/t/remote-desktop-with-hyprland/270
**Date**: 2024
**Confidence**: Medium (65%)
**Practical insight**: Sunshine (server) + Moonlight (client) uses KMS/DRM capture rather than Wayland portal, bypasses compositor key interception entirely. Good for LAN/local network gaming-style remote desktop. Heavier setup than VNC but keyboard issues are reported as non-existent.

---

## Code Examples Found

| Pattern | Description | Source |
|---------|-------------|--------|
| `vncviewer -FullscreenSystemKeys server:port` | Run TigerVNC fullscreen to auto-grab keys | tigervnc.org/doc/vncviewer.html |
| `Ctrl+Alt+G` in vncviewer | Manually grab keyboard in windowed mode | tigervnc.org/doc/vncviewer.html |
| Hyprland `submap = passthru` with only reset bind | Local passthru mode, all other keys reach VNC window | wiki.hypr.land/Configuring/Uncommon-tips--tricks/ |
| Toggle script using `hyprctl dispatch submap` | Scriptable toggle for remote desktop mode | github.com/basecamp/omarchy/discussions/3105 |

---

## Common Gotchas

| Gotcha | Solution | Source |
|--------|----------|--------|
| TigerVNC runs under Xwayland — Wayland inhibit protocol not available | Use fullscreen mode (`-FullscreenSystemKeys`) or Hyprland submap instead | tigervnc.org docs |
| Submap passthru reported "not working" for wayvnc modifier keys historically | Was a wayvnc bug, now fixed; submap is still valid for the client side | github.com/hyprwm/Hyprland/discussions/974 |
| Super key triggers local Hyprland even with VNC window focused | Hyprland owns ALL key events until compositor-level inhibit is negotiated | rustdesk issue #13013 |
| Entering submap with no notification is hard to track | Add `notify-send` or `dunstify` to the toggle script | omarchy discussions/3105 |
| `-FullscreenSystemKeys` only applies automatically in fullscreen | In windowed mode, use `Ctrl+Alt+G` to manually grab | tigervnc.org/doc/vncviewer.html |

---

## Best Practices (Community Consensus)

- For quickest fix with TigerVNC: run vncviewer in fullscreen — keys are auto-grabbed. Supported by multiple sources.
- For persistent windowed-mode use: configure a Hyprland passthru submap toggle on a spare key (e.g., `Super+F12`). Supported by Hyprland wiki + omarchy community.
- For a long-term clean solution: consider switching to RustDesk (self-hosted) which now uses the Wayland keyboard-shortcuts-inhibit protocol automatically. Supported by rustdesk issue #14302.
- Never rely on the VNC client alone fixing this on Wayland — the local compositor must cooperate, either via the inhibit protocol or a manually triggered submap.

---

## Anti-Patterns to Avoid

| Anti-pattern | Why Bad | Better Approach | Source |
|--------------|---------|-----------------|--------|
| Expecting TigerVNC windowed mode to forward Super key without any config | TigerVNC is Xwayland-based; local Hyprland grabs Super before X11 sees it | Use fullscreen or `Ctrl+Alt+G` grab | tigervnc.org |
| Defining many binds inside the passthru submap | Defeats the purpose — empty submap = all keys fall through | Only define the escape keybind | wiki.hypr.land |
| Using a passthru submap without a clear visual indicator | Easy to forget which mode you are in | Add notification on toggle | omarchy/3105 |

---

## Sources

| URL | Type | Votes/Engagement | Date |
|-----|------|------------------|------|
| https://tigervnc.org/doc/vncviewer.html | Official man page | — | Current |
| https://wayland.app/protocols/keyboard-shortcuts-inhibit-unstable-v1 | Protocol spec | — | Stable |
| https://github.com/rustdesk/rustdesk/issues/13013 | GitHub issue + PR | Active thread | Feb 2026 |
| https://github.com/basecamp/omarchy/discussions/3105 | Community discussion | Active | 2025 |
| https://wiki.hypr.land/Configuring/Uncommon-tips--tricks/ | Hyprland wiki | — | Current |
| https://github.com/hyprwm/Hyprland/discussions/974 | Hyprland discussion | Resolved | 2023 |
| https://forum.hypr.land/t/remote-desktop-with-hyprland/270 | Hyprland forum | — | 2024 |
| https://bbs.archlinux.org/viewtopic.php?id=177932 | Arch BBS | Solved | Older |

---

## Conflicts Between Sources

| Topic | Source A | Claim A | Source B | Claim B |
|-------|----------|---------|----------|---------|
| Submap passthru effectiveness | Hyprland discussion #974 | "submap for passthrough did not help" (old wayvnc bug) | omarchy/3105 + wiki | Submap works for disabling local grabs | Resolved: #974 was a wayvnc bug fixed in compositor; the submap approach is valid |
