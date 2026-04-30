# Knowledge System

How to capture courses so concepts link across them — instead of dying inside one course folder.

---

## Folders

| Folder | What goes here |
|---|---|
| `02_Courses/<course>/` | Course-specific stuff — lectures, assignments, syllabus index |
| `04_Concepts/` | Atomic, course-agnostic ideas — **one concept per note** |

---

## Workflow

1. **New course** → create `02_Courses/<name>/` with `_Index.md` (template: [[Templates/Course]]).
2. **Each lecture** → new file in `02_Courses/<name>/Lectures/` (template: [[Templates/Lecture]]). Reference concepts as `[[gradient-descent]]` instead of writing definitions inline.
3. **New concept encountered** → create `04_Concepts/<concept>.md` (template: [[Templates/Concept]]) with TL;DR + why it matters + first-seen link.
4. **Same concept in next course** → just link to the existing note. The Backlinks pane shows every lecture / course that touched it.

---

## Why atomic concepts

If `gradient descent` shows up in `cs231n` and `fastai`, both lectures `[[gradient-descent]]`. The concept note's Backlinks = *"this idea was touched in these courses, in these lectures."*

Without atomic notes you end up with two parallel definitions, no graph link, no way to see the cross-course pattern.

---

## Tagging

- `#course/<slug>` on lectures (e.g. `#course/cs231n`) — filter "where did this come from"
- `#concept` auto-applied by the Concept template
- `#topic/optimization`, `#topic/probability` — optional, helps Graph clustering

---

## Templates

- [[Templates/Course]] — course index / MOC
- [[Templates/Lecture]] — single lecture
- [[Templates/Concept]] — atomic concept note

Open via Obsidian's **Templates** plugin (`Cmd/Ctrl+P` → `Insert template`) or hotkey if bound.
