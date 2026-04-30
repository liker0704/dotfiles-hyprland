# Task Reference

Full format reference for `- [ ]` tasks in this vault.
The pipeline (`~/.local/bin/today-tasks` + `~/.local/bin/vault-task` +
Quickshell popup at `Win+O`) reads markdown checkboxes and surfaces them on:

- Quickshell bar — right-pill counter + click-through popup editor
- Hyprlock screen — top-right under the date
- 08:00 morning notification (`today-tasks-notify.timer`)
- Google Calendar — every timed task in today's daily becomes a GCal event
  with description; round-trip (add/edit/delete) propagates within seconds

> Lines tagged `#examples` or `#example` (or anything inside
> `Templates/`) are **ignored** by the parser — so this whole file is
> safely invisible to the bar pill / GCal push. Copy-paste freely.

---

## 1. Anatomy of a task line

```
- [ ]  HH:MM[-HH:MM]   text   ⏫|🔼|🔽   📅 YYYY-MM-DD   🔁 every {day,week,month,year}   #tag1 #tag2   description: free text
   │      │             │       │           │              │                                │             │
   │      │             │       │           │              │                                │             └ everything from here to EOL
   │      │             │       │           │              │                                └ free-form tags, multiple OK
   │      │             │       │           │              └ recurring → spawns next occurrence on done
   │      │             │       │           └ due date — hides task in popup until that day
   │      │             │       └ priority emoji (⏫ high · 🔼 med · 🔽 low · 🔺 highest · ⏬ lowest)
   │      │             └ task body — anything goes
   │      └ start time, optional `-end` for ranges (drives GCal duration)
   └ checkbox — `[ ]` open · `[x]` done · auto-stamps `✅ YYYY-MM-DD` when toggled in popup
```

Order matters where shown — keep this left-to-right when filling.
**Description must be last.** Once `description:` opens, everything to EOL
is captured as the body and isn't re-parsed (so it can contain `#`, emoji,
links, `📅`, etc. without polluting the real metadata).

---

## 2. Metadata fields

| Field        | Marker                            | Example                            | Notes |
|--------------|-----------------------------------|------------------------------------|---|
| Time start   | `HH:MM` prefix                    | `09:30 standup`                    | Single time → 60 min default GCal duration |
| Time range   | `HH:MM-HH:MM`                     | `14:00-15:30 review`               | Range drives GCal duration exactly |
| Time loose   | `HH MM` (space) prefix            | `09 30 standup`                    | Equivalent to `09:30` — Obsidian-friendly |
| Inline time  | `@HH:MM` or `at HH:MM` mid-line   | `coffee @14:30`                    | Used when prefix is awkward |
| Priority     | `⏫ 🔼 🔽 🔺 ⏬`                    | `... ⏫`                           | high / med / low / highest / lowest |
| Due date     | `📅 YYYY-MM-DD`                   | `... 📅 2026-05-15`                | Or bare `2026-05-15` / `15.05.2026` |
| Recurring    | `🔁 every {day,week,month,year}`  | `... 🔁 every week`                | On done: spawns next occurrence with 📅 advanced |
| Tag          | `#word`                           | `... #work #urgent`                | Free-form, multiple OK, kebab-case fine |
| Description  | `description: <text>`             | `... description: agenda + slides` | **Must be last** — goes to GCal description and popup hover-tooltip |
| Done date    | `✅ YYYY-MM-DD` (auto)             | `- [x] ... ✅ 2026-04-30`           | Stamped automatically by popup checkbox |
| Reserved tag | `#examples` / `#example`          | `... #examples`                    | **Parser skips the whole line** — use for templates / docs |

---

## 3. Links

### Wikilinks (Obsidian style — recommended for cross-vault refs)
```markdown
- [ ] follow up on [[02_Projects/Mobile Launch]]
- [ ] reread [[Daily Index]] before planning
```

### Markdown links
```markdown
- [ ] read the [vendor proposal](../00_Inbox/proposal.md)
- [ ] check [meeting notes](2026-04-29.md#decisions)
```

### External URLs — paste raw
```markdown
- [ ] join standup https://meet.example.com/abc
- [ ] PR review https://github.com/youruser/repo/pull/42
```

All three render in Obsidian, nvim (with `obsidian.nvim`), and stay
clickable in the popup tooltip when placed inside a `description:` body.

---

## 4. Tag conventions

Tags are free-form — invent your own. These are recommended buckets so
the popup search (`/`) and category filtering work consistently.

| Bucket   | Examples                                          |
|----------|---------------------------------------------------|
| Type     | `#note`, `#event`, `#task`, `#meeting`, `#call`    |
| Source   | `#work`, `#personal`, `#family`                    |
| Energy   | `#urgent`, `#waiting`, `#someday`, `#focus`        |
| Project  | `#mobile-launch`, `#q4-roadmap` (kebab-case)       |
| Habit    | `#habit`, `#routine`                               |
| Reserved | `#examples`, `#example` — **excluded from parser** |

---

## 5. Examples — every pattern

> All lines below are tagged `#examples`, so they're **invisible** to the
> bar pill, popup, GCal push, and notifications. This file also lives
> under `Templates/` which is excluded entirely. Copy → strip `#examples`
> → paste into your daily.

### 5.1  Plain note — capture a thought
```markdown
- [ ] note: reread chapter 4 before Friday #note #personal #examples
```

### 5.2  Quick task, no time
```markdown
- [ ] reply to recruiter email #task #work #examples
```

### 5.3  Timed event (creates GCal entry on today's daily)
```markdown
- [ ] 14:00 design review ⏫ #event #meeting #examples description: Q4 mockups, [[02_Projects/Mobile]]
```

### 5.4  Event with end time (range → GCal duration)
```markdown
- [ ] 09:30-10:00 daily standup 🔼 🔁 every day #event #work #examples description: round-robin, 1 blocker each
```

### 5.5  Future task with deadline
```markdown
- [ ] finalize offsite slides ⏫ 📅 2026-05-15 #task #work #examples description: roadmap, KPIs, hiring plan
```

### 5.6  Recurring habit
```markdown
- [ ] 22:00-23:00 read 🔽 🔁 every day #habit #examples
```

### 5.7  Phone / video call with link
```markdown
- [ ] 16:00-16:30 vendor call 🔼 #call #work #examples description: see https://meet.example.com/abc — agenda in [[02_Projects/Vendor X]]
```

### 5.8  Long-running async — `#waiting` until external party replies
```markdown
- [ ] follow up on contract amendment 📅 2026-05-08 #waiting #work #examples description: pinged on 2026-04-30 via email
```

### 5.9  Full-metadata showcase — exact left-to-right order
```markdown
- [ ] 09:30-10:30 weekly review ⏫ 📅 2026-05-04 🔁 every week #ritual #work #examples description: walk through last week's commits, plan top 3 — see [[02_Projects/Weekly]] and https://notion.so/weekly
```
That's: `time-range` → `text` → `priority ⏫` → `due 📅` → `recurring 🔁` → `tags` → `description:`.

### 5.10  Markdown link inside description
```markdown
- [ ] 11:00 code review #task #work #examples description: review [proposal](../00_Inbox/auth-rewrite.md) before merging
```

### 5.11  Done task (manually marked, with auto done-date)
```markdown
- [x] 13:00 lunch with team 🔼 #event #personal ✅ 2026-04-30 #examples
```

---

## 6. Where to put tasks

| Location | When | GCal? |
|---|---|---|
| `01_Daily/<today>.md` → `## Tasks` | Today's intent | ✅ (timed only) |
| `02_Projects/<project>.md` | Project-bound; surfaces in popup "Active" tab | ❌ |
| `00_Inbox/Quick Capture.md` | Use `note "..."` from terminal or Win+O capture | ❌ |
| `Templates/` | Reference / scaffolding | excluded entirely |
| `99_Archive/` | Cold storage | excluded entirely |

The cache merges all unfiltered locations. Only tasks in **today's daily
file** push to Google Calendar — that boundary keeps GCal events scoped
to "what I plan to do today".

---

## 7. What gets parsed vs ignored

Included:
- `- [ ]` open, `- [x]` / `- [X]` closed (latter goes to "Done" tab)
- `* [ ]` and `+ [ ]` checkbox markers also accepted

Ignored:
- Empty placeholders (`- [ ] ` with no body)
- Anything inside `%% ... %%` Obsidian comments
- Anything tagged `#examples` or `#example`
- Anything in `99_Archive/` or `Templates/` directories

---

## 8. Live-update timings

| Trigger                                | Latency        |
|----------------------------------------|----------------|
| Save any vault `*.md` → cache rewrite  | ~1 s (inotifywait + debounce) |
| Save **today's daily** → GCal sync     | ~3-6 s (inotify + gcalcli round-trip) |
| Background full pull from GCal         | every 15 min (`today-tasks.timer`) |
| Morning summary notification           | 08:00 (`today-tasks-notify.timer`) |

---

## 9. Editing via the popup

`Win+O` opens the bar; click the right pill → popup editor.

- `+` button or `N` key → add dialog
- Right-click row or `E` → edit dialog (multi-line description, all metadata fields)
- Click checkbox → toggle done (animates → file mutates → cache refreshes)
- `×` (hover) → delete
- `/` → focus search
- `1` `2` `3` `4` → switch tabs (Active / Today / Upcoming / Done)
- `Esc` → close dialog → close popup

All popup edits go through `~/.local/bin/vault-task`, which atomically
rewrites the source `.md` file. Newlines in the description box are
collapsed to spaces on save (vault is single-line).
