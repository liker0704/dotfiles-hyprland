# Web Research Report: Community Patterns

**Focus**: tmux window size stuck/wrong after fullscreen toggle — community patterns, workarounds, and config fixes
**Status**: COMPLETE

---

## Findings

### Finding 1: Root Cause — tmux constrains windows to smallest attached client
**Quote**: "tmux limits the dimensions of a window to the smallest of each dimension across all the sessions to which the window is attached. If it did not do this there would be no sensible way to display the whole window area for all the attached clients."
**Source**: https://til.hashrocket.com/posts/68544ddcd8-reclaiming-the-entire-window-in-tmux
**Date**: ~2020 (stable knowledge)
**Confidence**: High (95%) — matches official tmux man page behavior, reproduced across many sources
**Practical insight**: When you toggle a terminal to fullscreen and back, if tmux registers two logical clients (or if the terminal momentarily reports a different size), it locks to the smallest reported size. The dots/dead space at the bottom are the area tmux cannot render because its internal window size is smaller than the terminal viewport.

---

### Finding 2: Immediate one-shot fix — attach with -d to detach all other clients
**Quote**: "The easiest way to reclaim the entire window for your session is to attach to the session while forcing all other sessions to detach using the -d flag, which ensures your machine's dimensions are the ones that tmux uses when drawing the window."
**Source**: https://til.hashrocket.com/posts/68544ddcd8-reclaiming-the-entire-window-in-tmux
**Confidence**: High (90%) — widely cited, simple, immediate

```sh
tmux attach-session -d -t <session-name>
# or simply:
tmux attach -d
```

The `-d` flag evicts all other clients and forces the window size to match the current terminal.
**Caveat**: Disruptive in pair programming. Fine for solo dev.

---

### Finding 3: Permanent config fix — `window-size latest` (tmux >= 2.9)
**Quote**: "Set window-size latest in your ~/.tmux.conf to make windows adapt to the most recently attached client's screen size, instead of being constrained by the smallest client."
**Source**: https://tmuxai.dev/tmux-window-size/
**Date**: 2024
**Confidence**: High (85%) — matches tmux 2.9+ changelog, confirmed via multiple config blogs

```tmux
set-option -g window-size latest
```

Available values:

| Value | Behavior |
|-------|----------|
| `smallest` | Default — constrain to smallest client |
| `largest` | Constrain to largest client |
| `latest` | Follow most recently active client |
| `manual` | Fixed; do not auto-resize |

**Practical insight**: `latest` is the best option for solo use where you frequently toggle fullscreen or reconnect from different terminals. After you re-attach, the window takes on the current terminal's dimensions immediately.

---

### Finding 4: Alternative permanent fix — `aggressive-resize` (older approach, pre-2.9)
**Quote**: "Rather than constraining window size to the maximum size of any client connected to the session, constrain window size to the maximum size of any client connected to that window."
**Source**: https://mutelight.org/practical-tmux
**Confidence**: High (80%) — historically the canonical fix, well-documented

```tmux
setw -g aggressive-resize on
```

**How it differs from `window-size`**: `aggressive-resize` applies the "smallest attached" constraint only per-window (not per-session). If a small client is not viewing *that specific window*, it will not constrain it. `window-size latest` is the modern replacement and is more predictable.

**IMPORTANT caveat**: Incompatible with iTerm2 tmux integration (`tmux -CC`). Disable it when using iTerm2 in control mode.
**Source for caveat**: https://github.com/tmux-plugins/tmux-sensible/issues/24

---

### Finding 5: `aggressive-resize` meaning was inverted in tmux 2.9
**Quote**: (GitHub issue #1591) The behavior of `aggressive-resize` was reversed between tmux versions around 2.9. What it did before 2.9 is now handled more explicitly by the `window-size` option.
**Source**: https://github.com/tmux/tmux/issues/1591
**Date**: 2018 (stable historical context)
**Confidence**: Medium (70%) — relevant if running older tmux builds
**Practical insight**: If `aggressive-resize on` seems to make things worse on a newer tmux, check your tmux version (`tmux -V`). For tmux >= 2.9, prefer `set-option -g window-size latest` over `aggressive-resize`.

---

### Finding 6: Hook-based auto-resize with `resize-window -A`
**Quote**: "set-hook -g client-resized 'run-shell ...'" and "set-hook -g client-attached 'run-shell ...'"
**Source**: https://devel.tech/tips/n/tMuXz2lj/the-power-of-tmux-hooks/
**Confidence**: Medium-High (75%) — documented in hooks article, logically sound

```tmux
# Force window to resize to the largest connected client on every attach
set-hook -g client-attached 'resize-window -A'

# Normalize pane layout whenever the terminal is resized
set-hook -g client-resized 'select-layout -E'
```

The `-A` flag on `resize-window` instructs tmux to automatically resize the window to the largest client currently attached. Putting this in a `client-attached` hook means every reconnect (including after a fullscreen toggle that causes a detach/attach cycle) corrects the size immediately.

**Note**: `select-layout -E` distributes panes evenly — it fixes pane proportions but does not fix the window-level dimensions. Use both together.

---

### Finding 7: Plugin approach — tmux-resize-window-n-largest
**Quote**: "works by sorting clients according to either their height or their width, then setting up a hook that resizes the Window anytime there is focus on a window"
**Source**: https://github.com/freddieventura/tmux-resize-window-n-largest
**Confidence**: Low-Medium (50%) — niche plugin, low adoption signal
**Practical insight**: Overkill for the fullscreen toggle use case. The hook + `resize-window -A` approach achieves the same result without a plugin dependency.

---

## Code Examples Found

| Pattern | Description | Source |
|---------|-------------|--------|
| `tmux attach -d` | One-shot: detach others, inherit current terminal size | https://til.hashrocket.com/posts/68544ddcd8-reclaiming-the-entire-window-in-tmux |
| `set-option -g window-size latest` | Permanent: windows follow most recent client | https://tmuxai.dev/tmux-window-size/ |
| `setw -g aggressive-resize on` | Permanent (pre-2.9): per-window smallest-client constraint | https://mutelight.org/practical-tmux |
| `set-hook -g client-attached 'resize-window -A'` | Automatic: resize to largest on every attach | https://devel.tech/tips/n/tMuXz2lj/the-power-of-tmux-hooks/ |
| `set-hook -g client-resized 'select-layout -E'` | Automatic: normalize pane layout on terminal resize | https://dev.to/renuo/2-simple-configurations-to-supercharge-your-tmux-setup-5572 |
| `tmux resize-window -A` | Manual one-off command inside tmux to force resize | tmux man page |

---

## Common Gotchas

| Gotcha | Solution | Source |
|--------|----------|--------|
| Dots / dead space at bottom after fullscreen toggle | `tmux attach -d` or set `window-size latest` | https://til.hashrocket.com/posts/68544ddcd8-reclaiming-the-entire-window-in-tmux |
| `aggressive-resize` breaks iTerm2 tmux integration | Disable `aggressive-resize` when using `tmux -CC` | https://github.com/tmux-plugins/tmux-sensible/issues/24 |
| `aggressive-resize` behavior feels reversed on tmux 2.9+ | Migrate to `set-option -g window-size latest` | https://github.com/tmux/tmux/issues/1591 |
| `window-size` option not recognized | Requires tmux >= 2.9; use `aggressive-resize` on older builds | https://github.com/tmux/tmux/issues/2624 |
| `select-layout -E` does not fix window dimensions | Also run `resize-window -A` for window-level fix | https://devel.tech/tips/n/tMuXz2lj/the-power-of-tmux-hooks/ |
| `-d` flag disrupts pair programming | Use `prefix + D` (choose-client) to selectively detach one client | Community consensus |

---

## Best Practices (Community Consensus)

- Use `set-option -g window-size latest` as the modern, general-purpose fix — supported by 3+ sources
- Use `tmux attach -d` as a quick manual fix when the session is already stuck — supported by 2+ sources
- Avoid `aggressive-resize` if on tmux >= 2.9 — `window-size` supersedes it cleanly — supported by 2 sources
- Add `set-hook -g client-attached 'resize-window -A'` for fully automatic recovery on reconnect — 1 direct source, logically validated
- Do not combine `aggressive-resize on` with iTerm2 `-CC` integration — known incompatibility, multiple reports

---

## Anti-Patterns to Avoid

| Anti-pattern | Why Bad | Better Approach | Source |
|--------------|---------|-----------------|--------|
| Leaving default `window-size smallest` | Every fullscreen toggle or new attach can shrink all windows | `window-size latest` | https://tmuxai.dev/tmux-window-size/ |
| Running `resize-pane` to fix dots | Only adjusts pane divisions, not the window's reported dimensions | `resize-window -A` or `attach -d` | Community |
| Using `aggressive-resize on` with iTerm2 CC mode | Causes resize conflicts and visual glitches | Disable `aggressive-resize` for iTerm2 | https://github.com/tmux-plugins/tmux-sensible/issues/24 |
| Using `window-size largest` in shared sessions | Other users' larger terminal dictates your viewport | `window-size latest` for solo, `smallest` for strict shared parity | https://tmuxai.dev/tmux-window-size/ |

---

## Recommended `.tmux.conf` Additions

For solo developer use (fullscreen toggle, reconnecting, single terminal at a time):

```tmux
# Fix window stuck at wrong size after fullscreen toggle or reattach (tmux >= 2.9)
set-option -g window-size latest

# Auto-correct window size whenever a client attaches
set-hook -g client-attached 'resize-window -A'

# Normalize pane layout proportions when terminal is resized
set-hook -g client-resized 'select-layout -E'
```

For quick one-off fix without changing config:

```sh
# From a shell outside the broken session:
tmux attach -d -t <session>

# Or from inside tmux (command prompt: prefix + :):
resize-window -A
```

---

## Sources

| URL | Type | Engagement | Date |
|-----|------|------------|------|
| https://til.hashrocket.com/posts/68544ddcd8-reclaiming-the-entire-window-in-tmux | Blog / TIL | High (widely cited) | ~2020 |
| https://tmuxai.dev/tmux-window-size/ | Technical blog | Medium | 2024 |
| https://mutelight.org/practical-tmux | Blog (Screen to tmux migration) | High (longstanding reference) | ~2012, stable |
| https://chadaustin.me/2024/02/tmux-config/ | Blog | Medium | Feb 2024 |
| https://dev.to/renuo/2-simple-configurations-to-supercharge-your-tmux-setup-5572 | Dev.to blog | Medium | 2023 |
| https://devel.tech/tips/n/tMuXz2lj/the-power-of-tmux-hooks/ | Technical blog | Medium | ~2019 |
| https://github.com/tmux-plugins/tmux-sensible/issues/24 | GitHub issue | Medium | 2016+ |
| https://github.com/tmux/tmux/issues/1591 | GitHub issue | Medium | 2018 |
| https://github.com/tmux/tmux/issues/2624 | GitHub issue | Medium | 2019 |
| https://github.com/freddieventura/tmux-resize-window-n-largest | GitHub plugin | Low | 2023 |

---

## Conflicts Between Sources

| Topic | Source A | Claim A | Source B | Claim B |
|-------|----------|---------|----------|---------|
| `aggressive-resize` usefulness | mutelight.org | Highly recommended, much more reasonable than default | tmux-sensible#24 | Incompatible with iTerm2 CC mode — must be disabled |
| `aggressive-resize` vs `window-size` | chadaustin.me (2024) | Still uses `aggressive-resize on` in modern config | tmuxai.dev (2024) | `window-size` is the proper modern replacement |
| Best `window-size` value for solo use | tmuxai.dev | Recommends `latest` | tmuxai.dev | Also mentions `largest` maximizes space for all attached clients |
