pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// TaskService — single source of truth for the task editor UI.
// Reads ~/.cache/today-tasks.json (written atomically by `today-tasks`),
// exposes typed buckets + stats, and forwards mutations to ~/.local/bin/vault-task.
// Reactivity loop:
//   UI action → vault-task mutates .md file → today-tasks-watch service →
//   today-tasks rewrites JSON (atomic rename) → FileView fires onLoaded →
//   jsonText property updates → all bindings refresh.
QtObject {
    id: root

    // ---- Reactive state, populated from JSON cache ----
    property var events: []
    property var today: []
    property var other: []
    property var completed: []
    property string generatedAt: ""
    property var counts: ({ events: 0, today: 0, other: 0, completed: 0, overdue: 0, upcoming: 0 })
    property bool ready: false

    // ---- Cache file watcher ----
    // The aggregator writes the cache via tmpfile + atomic rename, which lands
    // as an inotify MOVE_TO on the parent directory rather than a MODIFY on
    // the existing inode. FileView.watchChanges still detects the change but
    // its in-memory buffer is left pointing at the old contents — calling
    // text() right then returns stale data. Force a fresh read with reload()
    // and parse on the subsequent onLoaded.
    property FileView _cacheView: FileView {
        id: _cacheView
        path: Quickshell.env("HOME") + "/.cache/today-tasks.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._reloadFromCache()
    }

    function _reloadFromCache() {
        var raw = ""
        try { raw = _cacheView.text() } catch (e) { raw = "" }
        if (!raw || raw.length === 0) return
        try {
            var d = JSON.parse(raw)
            root.events      = d.events    || []
            root.today       = d.today     || []
            root.other       = d.other     || []
            root.completed   = d.completed || []
            root.generatedAt = d.generated_at || ""
            root.counts      = d.counts || root.counts
            root.ready = true
        } catch (e) {
            // ignore — partial write or malformed; FileView will retry on next change
        }
    }

    Component.onCompleted: _reloadFromCache()

    // ---- Derived helpers ----
    function tasksToday()    { return root.today }
    function tasksUpcoming() { return (root.other || []).filter(t => t.due && t.due > _todayIso()) }
    function tasksOverdue()  { return _allActive().filter(t => t.overdue === true) }
    function tasksOther()    { return root.other }
    function tasksCompleted(){ return root.completed }

    function _todayIso() {
        var d = new Date()
        return d.getFullYear() + "-" +
               String(d.getMonth()+1).padStart(2, "0") + "-" +
               String(d.getDate()).padStart(2, "0")
    }
    function _allActive() {
        return (root.today || []).concat(root.other || [])
    }

    function tasksByPriority(level) {
        return _allActive().filter(t => t.priority === level)
    }
    function tasksByCategory(cat) {
        return _allActive().filter(t => (t.categories || []).indexOf(cat) >= 0)
    }
    function searchTasks(query) {
        var q = (query || "").toLowerCase().trim()
        if (q === "") return _allActive()
        return _allActive().filter(function(t) {
            if ((t.text || "").toLowerCase().indexOf(q) >= 0) return true
            if ((t.categories || []).some(c => c.toLowerCase().indexOf(q) >= 0)) return true
            if ((t.priority || "").toLowerCase().indexOf(q) >= 0) return true
            return false
        })
    }

    // ---- Stats ----
    readonly property var stats: {
        var totalActive = root.counts.today + root.counts.other
        var totalAll = totalActive + root.counts.completed
        return {
            todayCount:    root.counts.today    || 0,
            otherCount:    root.counts.other    || 0,
            completedCount: root.counts.completed || 0,
            overdueCount:  root.counts.overdue  || 0,
            upcomingCount: root.counts.upcoming || 0,
            eventCount:    root.counts.events   || 0,
            totalActive:   totalActive,
            totalAll:      totalAll,
            completionRate: totalAll > 0 ? Math.round(100 * root.counts.completed / totalAll) : 0,
        }
    }

    // ---- Mutations (fire-and-forget; cache refreshes via watcher) ----
    // Use absolute path — execDetached doesn't go through shell PATH lookup
    // reliably across Quickshell versions.
    readonly property string _vaultTaskBin: Quickshell.env("HOME") + "/.local/bin/vault-task"

    function _execTask(args) {
        Quickshell.execDetached([root._vaultTaskBin].concat(args))
    }

    function addTask(opts) {
        var args = ["add", opts.text || ""]
        if (opts.time)       args.push("--time", opts.time)
        if (opts.endTime)    args.push("--end", opts.endTime)
        if (opts.due)        args.push("--due", opts.due)
        if (opts.priority)   args.push("--priority", opts.priority)
        if (opts.recurring)  args.push("--recur", opts.recurring)
        if (opts.categories && opts.categories.length > 0)
            args.push("--tag", opts.categories.join(","))
        if (opts.description)
            args.push("--description", opts.description)
        if (opts.file)       args.push("--file", opts.file)
        _execTask(args)
    }

    function toggleTask(id) {
        if (!id) return
        _execTask(["toggle", id])
    }

    function deleteTask(id) {
        if (!id) return
        _execTask(["delete", id])
    }

    function editTask(id, opts) {
        if (!id) return
        var args = ["edit", id]
        // Only include keys that are explicitly set (string fields use empty
        // string to mean "clear", undefined to mean "leave as-is").
        if (opts.text        !== undefined) args.push("--text",        opts.text)
        if (opts.time        !== undefined) args.push("--time",        opts.time)
        if (opts.endTime     !== undefined) args.push("--end",         opts.endTime)
        if (opts.due         !== undefined) args.push("--due",         opts.due)
        if (opts.priority    !== undefined) args.push("--priority",    opts.priority)
        if (opts.recurring   !== undefined) args.push("--recur",       opts.recurring)
        if (opts.categories  !== undefined) args.push("--tag",         (opts.categories || []).join(","))
        if (opts.description !== undefined) args.push("--description", opts.description)
        _execTask(args)
    }

    // Run the aggregator on demand (e.g. for force-refresh button in UI).
    function refresh() {
        Quickshell.execDetached(["bash", "-lc", "today-tasks"])
    }
}
