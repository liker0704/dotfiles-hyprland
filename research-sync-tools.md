# Web Research Report: Community Patterns

**Focus**: On-demand bidirectional file sync between two Linux machines on LAN
**Status**: COMPLETE

---

## Findings

### Finding 1: Unison is the canonical on-demand bidirectional sync tool — but has a critical version mismatch gotcha

**Quote**: "Both versions must be compiled with the same OCaml compiler version" (pre-2.52) and "Fatal error during unmarshaling (input_value: ill-formed message), possibly because client and server have been compiled with different versions of the OCaml compiler."
**Source**: https://github.com/bcpierce00/unison/issues/18 / https://lists.seas.upenn.edu/pipermail/unison-hackers/2020-August/001972.html
**Votes/Engagement**: Multiple GitHub issues, Ubuntu bug reports
**Date**: Ongoing, partially resolved in 2.52+
**Confidence**: High (90%)
**Practical insight**: If both machines run the same distro and the same package manager version, you're fine. The moment they diverge (e.g., one is on Ubuntu 20.04, one on 22.04), you get cryptic marshal errors at runtime, not at install time. As of unison 2.52, version compatibility across different OCaml compiler builds was finally introduced. Check `unison -version` on both machines before relying on it.

---

### Finding 2: Unison -auto and -batch flags make it truly one-shot scriptable

**Quote**: "-auto: automatically accept default (nonconflicting) actions. -batch: batch mode: ask no questions at all (aborts on conflicts rather than proceeding destructively)"
**Source**: https://man.archlinux.org/man/unison.1.en / https://dou-meishi.github.io/org-blog/2024-01-07-ReviewUnison/advanced.html
**Date**: 2024
**Confidence**: High (95%)
**Practical insight**: The recommended one-shot workflow is:
- `unison myprofile -auto` — propagates all non-conflicting changes, stops and reports conflicts without acting on them.
- `unison myprofile -batch` — fully automated, but aborts on large deletes (controlled by `confirmbigdel = true` default) rather than silently destroying data.
- Store roots and ignore patterns in `~/.unison/myprofile.prf`, then `unison myprofile` is your daily `sync` command.

---

### Finding 3: Unison directory rename + ignored files = silent data loss

**Quote**: "Because Unison understands the rename as a delete plus a create, any ignored files in the directory will be lost."
**Source**: https://dou-meishi.github.io/org-blog/2024-01-07-ReviewUnison/advanced.html
**Date**: January 2024
**Confidence**: High (85%)
**Practical insight**: If you ignore `node_modules/`, `.git/`, or build artifacts inside a project directory, and you rename that project directory on one machine, Unison will delete it on the other side and recreate the directory — without the ignored files. The ignored files on that side are gone. Add explicit `ignore = BelowPath` patterns carefully.

---

### Finding 4: Unison disconnected drive / missing root = destructive sync

**Quote**: "When a USB drive is ejected and Unison runs again, it may attempt to delete your entire replica since it views the empty drive as the authoritative state."
**Source**: https://dou-meishi.github.io/org-blog/2024-01-07-ReviewUnison/advanced.html
**Date**: January 2024
**Confidence**: High (85%)
**Practical insight**: For LAN sync: if machine B is offline when you run `unison`, Unison will error and refuse to proceed (because SSH fails). This is actually safe. But this is why running `unison` with `ssh://` roots is safer than using NFS/SSHFS mounts where the mount point might exist but be empty.

---

### Finding 5: Rsync is one-way by design — bidirectional requires wrappers with real tradeoffs

**Quote**: "If you do each one-way sync explicitly in sequence as you have done in your script, this will not get the goal you want as it will delete / overwrite some changes."
**Source**: https://www.raysync.io/news/rsync-two-way-sync/
**Date**: 2024
**Confidence**: High (90%)
**Practical insight**: Naive A→B then B→A rsync will cause the second pass to undo changes from the first pass. You need a wrapper that either: (a) tracks a file list snapshot to detect changes since last sync, or (b) uses timestamps carefully. The community-maintained wrappers:
- **osync** (https://github.com/deajan/osync): Most complete, handles soft-delete, conflict backups, runs on-demand or daemon. Maintainer notes "not very active since a couple of years" in 2024. Had race conditions in parallel mode.
- **bsync** (https://github.com/dooblem/bsync): Simpler, uses `find` snapshots. Less active.
- **rclone bisync**: See Finding 6.

---

### Finding 6: rclone bisync works on-demand but has a "first run" initialization requirement and conflict edge cases

**Quote**: "Bisync is considered an advanced command, so use with care. Make sure you have read and understood the entire manual (especially the Limitations section) before using, or data loss can result."
**Source**: https://rclone.org/bisync/
**Date**: 2024 (actively maintained)
**Confidence**: High (85%)
**Practical insight**:
- First run requires `--resync` flag to build the baseline file list, or it will refuse to run.
- Conflict detection: if a file changes on both sides between runs, bisync detects it and keeps both versions (renamed with conflict suffix).
- On local paths, checksum computation is done in real-time (no caching), which can be slow on large trees — use `--no-checksum` and rely on modtime for LAN use.
- It runs on-demand via: `rclone bisync /home/user/projects sftp:machine2/home/user/projects`
- rclone handles SSH natively, no extra config needed beyond `~/.ssh/config`.

---

### Finding 7: Mutagen requires a persistent daemon and is designed for ongoing dev workflows, not on-demand sync

**Quote**: "Mutagen now does daemon start automatically" and "Once everything is synced, Mutagen runs at 1-2% CPU and approximately 50 MB RAM"
**Source**: https://news.ycombinator.com/item?id=33225703 / https://mutagen.io/documentation/synchronization/
**Date**: 2022-2024
**Confidence**: High (88%)
**Practical insight**: Mutagen keeps a background daemon running that watches filesystems and syncs in sub-second latency. You can `mutagen sync create` to start a session and `mutagen sync terminate` to stop it, but the model is fundamentally persistent sessions, not one-shot operations. For a LAN dev workflow where you want to `sync` and walk away, it's overkill and the daemon overhead (plus auto-start behavior) is friction. Where it shines: local→remote Docker container or local→remote SSH host during an active dev session. Conflict resolution is less interactive than Unison — you manually delete the losing file.

---

### Finding 8: Mutagen's "two-way-resolved" mode silently destroys data — alpha always wins

**Quote**: "two-way-resolved: the alpha endpoint automatically wins all conflicts, including cases where alpha's deletions would overwrite beta's modifications."
**Source**: https://mutagen.io/documentation/synchronization/
**Date**: 2024
**Confidence**: High (95%)
**Practical insight**: The default `two-way-safe` mode is safe (preserves both sides on conflict), but many tutorials suggest `two-way-resolved` for simplicity — this will silently delete changes on the beta side whenever there's any conflict, including deletions from alpha overwriting edits on beta.

---

### Finding 9: Syncthing fundamentally cannot do on-demand sync — it is a daemon-only tool

**Quote**: "Is there any plans on adding sync on demand?" (feature request, no official response)
**Source**: https://forum.syncthing.net/t/is-there-any-plans-on-adding-sync-on-demand/22391
**Date**: 2023
**Confidence**: High (95%)
**Practical insight**: Syncthing has no concept of one-shot operation. The closest workaround is: start it, wait for sync to complete, stop it. You can script this with `systemctl start syncthing`, poll the REST API for sync completion, then `systemctl stop syncthing`. But this is fighting the tool's design. The CLI `syncthing cli config folders $id paused set true/false` can pause individual folders, but the daemon must be running. For on-demand use: don't use Syncthing.

---

### Finding 10: lsyncd is one-way only — eliminates it from bidirectional use cases

**Quote**: "lsyncd performs one-way sync, pushing from source to destination"
**Source**: https://www.saashub.com/compare-syncthing-vs-lsyncd
**Date**: 2024
**Confidence**: High (95%)
**Practical insight**: lsyncd is an inotify-triggered rsync daemon. It's excellent for "keep machine B as a mirror of machine A in real-time" but has no concept of changes flowing back from B to A. Eliminates itself from the use case entirely.

---

## Code Examples Found

| Pattern | Description | Source |
|---------|-------------|--------|
| `unison myprofile -auto` | Non-interactive sync, stops on conflicts | Arch man page |
| `unison myprofile -batch` | Fully automated, aborts on large deletes | Arch man page |
| `rclone bisync ~/projects sftp:pc2/home/user/projects --resync` | First-time init for rclone bisync | rclone docs |
| `rclone bisync ~/projects sftp:pc2/home/user/projects` | Subsequent on-demand runs | rclone docs |
| `syncthing cli config folders $id paused set true` | Pause a folder via CLI (daemon must run) | Syncthing forum |

---

## Common Gotchas

| Gotcha | Solution | Source |
|--------|----------|--------|
| Unison version mismatch across distros | Ensure both machines run identical unison version; prefer 2.52+ | GitHub issues, Ubuntu bug |
| Unison ignores pattern + directory rename = data loss | Never rename dirs with ignored children, or un-ignore before rename | dou-meishi blog 2024 |
| Naive A→B, B→A rsync double-pass overwrites changes | Use unison, osync, or rclone bisync instead | raysync.io 2024 |
| rclone bisync refuses to run without --resync on first use | Always run `--resync` on first use to build baseline | rclone docs |
| Mutagen `two-way-resolved` silently deletes beta changes | Use `two-way-safe` (default) unless you understand the tradeoff | mutagen docs |
| Syncthing cannot do one-shot sync | Use unison or rclone bisync instead | Syncthing forum |
| osync monitor mode only watches initiator side | Target changes only sync when initiator changes or after 600s timeout | osync README |

---

## Best Practices (Community Consensus)

- Use Unison for interactive or scripted on-demand bidirectional sync — supported by multiple forums, wikis, blog posts
- Store Unison settings in a `.prf` profile file so the daily command is just `unison myprofile` — supported by ArchWiki, softprayog, linuxjournal
- Add `auto = true` to your Unison profile for non-conflicting changes; review actual conflicts manually — supported by orgmode.org tutorial, linux journal
- Always use SSH roots (`ssh://`) rather than NFS/SSHFS mounts in Unison to get safe "remote unavailable" errors — community consensus
- For rclone bisync, avoid checksum mode on large LAN directories; modtime-based is fast enough — rclone forum
- Exclude build artifacts and `node_modules` from sync — every source, universal consensus

---

## Anti-Patterns to Avoid

| Anti-pattern | Why Bad | Better Approach | Source |
|--------------|---------|-----------------|--------|
| `rsync A→B && rsync B→A` script | Second pass silently overwrites changes from first pass | Use unison or rclone bisync | raysync.io |
| Running Syncthing for on-demand sync | No one-shot mode, requires permanent daemon, heavyweight setup | Use unison | Syncthing forum |
| Using lsyncd for bidirectional sync | One-way only by design | Use unison | saashub comparison |
| Mutagen `two-way-resolved` for equal-priority machines | Alpha silently destroys beta edits | Use `two-way-safe` or unison | mutagen docs |
| Unison `-batch` without understanding `confirmbigdel` | Will abort silently on large deletes instead of proceeding | Use `-auto` first, review output | unison man page |
| Ignoring unison version before first run | Cryptic marshal errors at sync time | `unison -version` on both hosts | GitHub issue #18 |

---

## Practical Recommendation (Community-Derived)

For your specific use case (on-demand `sync` command, ~/projects, two Linux machines on LAN):

**Tier 1 — Unison** is the right tool. It was designed exactly for this. Profile-based, SSH-native, bidirectional, no daemon, conflict-aware interactive or scriptable. The only real gotcha is version matching between machines.

**Tier 2 — rclone bisync** if you already use rclone or want something more actively developed. Requires first-run `--resync`, runs on-demand, SSH-native. Less interactive conflict UI than Unison but handles the LAN case cleanly.

**Skip** — Syncthing (daemon-only), lsyncd (one-way), Mutagen (persistent daemon, dev-container focus), raw rsync (one-way without wrappers).

---

## Sources

| URL | Type | Votes/Engagement | Date |
|-----|------|------------------|------|
| https://man.archlinux.org/man/unison.1.en | Reference manual | N/A | Current |
| https://dou-meishi.github.io/org-blog/2024-01-07-ReviewUnison/advanced.html | Technical blog | N/A | Jan 2024 |
| https://github.com/bcpierce00/unison/issues/18 | GitHub issue | Active | Ongoing |
| https://lists.seas.upenn.edu/pipermail/unison-hackers/2020-August/001972.html | Mailing list | N/A | 2020 |
| https://github.com/bcpierce00/unison/wiki/2.52-Migration-Guide | GitHub wiki | N/A | 2022+ |
| https://rclone.org/bisync/ | Official docs | N/A | 2024 |
| https://forum.rclone.org/t/best-way-to-sync-between-two-machines/43398 | Community forum | N/A | 2023 |
| https://mutagen.io/documentation/synchronization/ | Official docs | N/A | 2024 |
| https://news.ycombinator.com/item?id=33225703 | HN discussion | 200+ points | 2022 |
| https://forum.syncthing.net/t/is-there-any-plans-on-adding-sync-on-demand/22391 | Feature request | N/A | 2023 |
| https://forum.syncthing.net/t/stcli-or-how-to-pause-resume-sync-from-cli-in-2022/19345 | Community forum | N/A | 2022 |
| https://github.com/deajan/osync | GitHub README | 1.8k commits | 2024 |
| https://github.com/dooblem/bsync | GitHub | Small project | Active |
| https://www.raysync.io/news/rsync-two-way-sync/ | Technical article | N/A | 2024 |
| https://www.saashub.com/compare-syncthing-vs-lsyncd | Comparison | N/A | 2024 |

---

## Conflicts Between Sources

| Topic | Source A | Claim A | Source B | Claim B |
|-------|----------|---------|----------|---------|
| Unison version compat | Pre-2.52 mailing list | Must match exactly or get fatal errors | 2.52 migration guide | 2.52+ allows different versions and OCaml builds |
| Mutagen overhead | HN discussion | 1-2% CPU, 50MB RAM — acceptable | ddev issue #5539 | Initial sync can take 10+ minutes on large repos |
| osync maintenance | GitHub README | Actively maintained, recent releases | Maintainer comments | "Not very active since a couple of years" |
