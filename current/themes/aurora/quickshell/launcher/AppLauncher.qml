import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import ".."

Scope {
    id: root

    property bool visible: false
    property string searchText: ""
    property string baseMode: "apps"
    property bool searchCleared: true
    property int maxEntries: 120

    readonly property var modeChips: [
        { id: "apps", label: "Apps", key: "Ctrl+1" },
        { id: "combi", label: "Combi", key: "Ctrl+2" },
        { id: "windows", label: "Windows", key: "Ctrl+3" },
        { id: "actions", label: "Actions", key: "Ctrl+4" },
        { id: "obsidian", label: "Obsidian", key: "Ctrl+5" }
    ]

    function lower(value) {
        return (value || "").toString().toLowerCase()
    }

    function shellQuote(value) {
        return "'" + (value || "").toString().replace(/'/g, "'\\''") + "'"
    }

    function escapeRegex(value) {
        return (value || "").toString().replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    }

    function normalizeMode(mode) {
        switch (mode) {
        case "apps":
        case "windows":
        case "actions":
        case "obsidian":
        case "shell":
        case "calc":
        case "web":
            return mode
        default:
            return "combi"
        }
    }

    function modeLabel(mode) {
        switch (mode) {
        case "apps":
            return "Apps"
        case "windows":
            return "Windows"
        case "actions":
            return "Actions"
        case "obsidian":
            return "Obsidian"
        case "shell":
            return "Run"
        case "calc":
            return "Calculator"
        case "web":
            return "Web"
        default:
            return "Combi"
        }
    }

    function modePlaceholder(mode) {
        switch (mode) {
        case "windows":
            return "Search windows..."
        case "actions":
            return "Search actions..."
        case "obsidian":
            return "Obsidian actions or quick note text..."
        case "shell":
            return "Run command..."
        case "calc":
            return "Type expression..."
        case "web":
            return "Search web query..."
        case "apps":
            return "Search apps..."
        default:
            return "Search apps, actions, windows..."
        }
    }

    function modeHelp(mode) {
        if (mode === "obsidian") {
            return "Type text + Enter to append quick note. Prefixes: >cmd  =calc  ?web"
        }

        if (mode === "shell") {
            return "Run shell command. Prefixes: !a !w !x !o !r"
        }

        return "Prefixes: !a apps  !w windows  !x actions  !o obsidian  !r run  >cmd  =calc  ?web"
    }

    function openMode(mode, query) {
        baseMode = normalizeMode(mode)
        visible = true
        searchText = query || ""
        searchCleared = searchText.length === 0

        if (searchInput) {
            searchInput.text = searchText
            searchInput.cursorPosition = searchInput.text.length
            searchInput.forceActiveFocus()
        }

        if (appList) appList.currentIndex = 0
    }

    function cycleBaseMode(step) {
        var order = ["apps", "combi", "windows", "actions", "obsidian"]
        var currentIndex = order.indexOf(baseMode)
        if (currentIndex < 0) currentIndex = 0

        var nextIndex = (currentIndex + step + order.length) % order.length
        openMode(order[nextIndex], "")
    }

    function toggle() {
        if (visible) {
            hide()
            return
        }

        openMode("apps", "")
    }

    function open(query) {
        openMode("apps", query || "")
    }

    function openObsidianMenu() {
        openMode("obsidian", "")
    }

    function hide() {
        visible = false
        searchText = ""
        searchCleared = true
    }

    function parseQueryState() {
        var raw = (searchText || "").trim()
        if (raw === "") return { mode: baseMode, query: "" }

        var bangMatch = raw.match(/^!([a-z]+)\s*(.*)$/i)
        if (bangMatch) {
            var token = lower(bangMatch[1])
            var rest = bangMatch[2] || ""

            if (token === "a" || token === "app" || token === "apps" || token === "d" || token === "drun") return { mode: "apps", query: rest }
            if (token === "w" || token === "win" || token === "window" || token === "windows") return { mode: "windows", query: rest }
            if (token === "x" || token === "act" || token === "action" || token === "actions") return { mode: "actions", query: rest }
            if (token === "o" || token === "obs" || token === "obsidian") return { mode: "obsidian", query: rest }
            if (token === "r" || token === "run" || token === "cmd") return { mode: "shell", query: rest }
            if (token === "m" || token === "all" || token === "combi") return { mode: "combi", query: rest }
        }

        if (raw.startsWith(">")) return { mode: "shell", query: raw.slice(1).trim() }
        if (raw.startsWith("=")) return { mode: "calc", query: raw.slice(1).trim() }
        if (raw.startsWith("?")) return { mode: "web", query: raw.slice(1).trim() }

        return { mode: baseMode, query: raw }
    }

    readonly property var queryState: parseQueryState()

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function open(query: string): void { root.open(query) }
        function obsidianMenu(): void { root.openObsidianMenu() }
        function setMode(mode: string): void { root.openMode(mode, "") }
    }

    property var globalActions: [
        {
            entryType: "action",
            actionId: "switch_mode_combi",
            name: "Switch to Combi mode",
            genericName: "Apps + Actions + Windows",
            icon: "view-list-symbolic",
            keywords: "mode combi all"
        },
        {
            entryType: "action",
            actionId: "switch_mode_apps",
            name: "Switch to Apps mode",
            genericName: "Desktop applications",
            icon: "view-grid-symbolic",
            keywords: "mode apps drun"
        },
        {
            entryType: "action",
            actionId: "switch_mode_windows",
            name: "Switch to Windows mode",
            genericName: "Window switcher",
            icon: "window-duplicate",
            keywords: "mode windows"
        },
        {
            entryType: "action",
            actionId: "switch_mode_actions",
            name: "Switch to Actions mode",
            genericName: "System actions",
            icon: "applications-system",
            keywords: "mode actions commands"
        },
        {
            entryType: "action",
            actionId: "switch_mode_obsidian",
            name: "Switch to Obsidian mode",
            genericName: "Notes actions",
            icon: "md.obsidian.Obsidian",
            keywords: "mode obsidian notes"
        },
        {
            entryType: "action",
            actionId: "open_terminal",
            name: "Open terminal",
            genericName: "kitty",
            icon: "utilities-terminal",
            keywords: "terminal shell"
        },
        {
            entryType: "action",
            actionId: "open_browser",
            name: "Open browser",
            genericName: "zen-browser",
            icon: "web-browser",
            keywords: "browser web"
        },
        {
            entryType: "action",
            actionId: "open_home_folder",
            name: "Open home folder",
            genericName: "$HOME",
            icon: "folder-open",
            keywords: "files folder"
        },
        {
            entryType: "action",
            actionId: "lock_screen",
            name: "Lock screen",
            genericName: "hyprlock",
            icon: "system-lock-screen",
            keywords: "lock"
        },
        {
            entryType: "action",
            actionId: "session_menu",
            name: "Open session menu",
            genericName: "Quickshell session",
            icon: "system-shutdown",
            keywords: "power logout reboot"
        },
        {
            entryType: "action",
            actionId: "reload_hypr",
            name: "Reload Hyprland config",
            genericName: "hyprctl reload",
            icon: "view-refresh",
            keywords: "reload hyprland"
        },
        {
            entryType: "action",
            actionId: "toggle_focus_mode",
            name: "Toggle focus mode",
            genericName: "FocusMode.sh",
            icon: "preferences-system-time",
            keywords: "focus mode"
        }
    ]

    property var obsidianActions: [
        {
            entryType: "action",
            actionId: "open_vault",
            name: "Open vault",
            genericName: "MainVault",
            icon: "md.obsidian.Obsidian",
            keywords: "obsidian vault notes"
        },
        {
            entryType: "action",
            actionId: "open_quick_capture",
            name: "Open quick capture",
            genericName: "00_Inbox/Quick Capture.md",
            icon: "document-edit",
            keywords: "obsidian quick capture inbox"
        },
        {
            entryType: "action",
            actionId: "open_daily",
            name: "Open today daily",
            genericName: "01_Daily",
            icon: "view-calendar",
            keywords: "obsidian daily today"
        },
        {
            entryType: "action",
            actionId: "open_vault_folder",
            name: "Open vault folder",
            genericName: "$HOME/Notes/MainVault",
            icon: "folder-open",
            keywords: "obsidian folder files"
        },
        {
            entryType: "action",
            actionId: "switch_mode_combi",
            name: "Back to launcher",
            genericName: "Combi mode",
            icon: "go-previous",
            keywords: "back launcher"
        }
    ]

    function actionMatches(action, queryLower) {
        if (queryLower === "") return true

        var haystack = [
            action.name || "",
            action.genericName || "",
            action.keywords || ""
        ].join(" ").toLowerCase()

        return haystack.indexOf(queryLower) >= 0
    }

    function appMatches(entry, queryLower) {
        if (queryLower === "") return true

        if (lower(entry.name).indexOf(queryLower) >= 0) return true
        if (lower(entry.genericName).indexOf(queryLower) >= 0) return true
        if (lower(entry.comment).indexOf(queryLower) >= 0) return true

        var keywords = entry.keywords || []
        for (var i = 0; i < keywords.length; i++) {
            if (lower(keywords[i]).indexOf(queryLower) >= 0) return true
        }

        var categories = entry.categories || []
        for (var j = 0; j < categories.length; j++) {
            if (lower(categories[j]).indexOf(queryLower) >= 0) return true
        }

        return false
    }

    function appSort(a, b, queryLower) {
        if (queryLower !== "") {
            var aPrefix = lower(a.name).indexOf(queryLower) === 0
            var bPrefix = lower(b.name).indexOf(queryLower) === 0
            if (aPrefix !== bPrefix) return aPrefix ? -1 : 1

            var aContains = lower(a.name).indexOf(queryLower) >= 0
            var bContains = lower(b.name).indexOf(queryLower) >= 0
            if (aContains !== bContains) return aContains ? -1 : 1
        }

        return (a.name || "").localeCompare(b.name || "")
    }

    function looksLikePath(text) {
        return text.startsWith("/") || text.startsWith("./") || text.startsWith("../")
    }

    function looksLikeMath(text) {
        return /^[0-9+\-*/().,%^\s]+$/.test(text) && /[0-9]/.test(text)
    }

    function limitEntries(list, limit) {
        if (list.length <= limit) return list
        return list.slice(0, limit)
    }

    function appendLimited(target, source, limit) {
        for (var i = 0; i < source.length; i++) {
            if (target.length >= limit) break
            target.push(source[i])
        }
    }

    function buildAppEntries(queryLower) {
        var appsModel = DesktopEntries.applications
        var apps = appsModel && appsModel.values ? appsModel.values : []
        var list = []

        for (var i = 0; i < apps.length; i++) {
            var app = apps[i]
            if (appMatches(app, queryLower)) list.push(app)
        }

        list.sort(function(a, b) { return appSort(a, b, queryLower) })
        return limitEntries(list, maxEntries)
    }

    function buildWindowEntries(queryLower) {
        var topsModel = ToplevelManager.toplevels
        var tops = topsModel && topsModel.values ? topsModel.values : []
        var list = []

        for (var i = 0; i < tops.length; i++) {
            var top = tops[i]
            var title = (top.title || "").trim()
            var appId = (top.appId || "").trim()
            var name = title !== "" ? title : appId
            if (name === "") continue

            var searchable = lower(name + " " + appId)
            if (queryLower !== "" && searchable.indexOf(queryLower) < 0) continue

            list.push({
                entryType: "window",
                windowRef: top,
                activated: !!top.activated,
                name: name,
                windowTitle: title,
                genericName: appId,
                appIdExact: appId,
                icon: appId !== "" ? appId : "application-x-executable",
                keywords: searchable
            })
        }

        list.sort(function(a, b) {
            if (a.activated !== b.activated) return a.activated ? -1 : 1

            var aPrefix = lower(a.name).indexOf(queryLower) === 0
            var bPrefix = lower(b.name).indexOf(queryLower) === 0
            if (aPrefix !== bPrefix) return aPrefix ? -1 : 1

            return (a.name || "").localeCompare(b.name || "")
        })

        return limitEntries(list, maxEntries)
    }

    function buildActionEntries(queryText, queryLower) {
        var list = []

        for (var i = 0; i < globalActions.length; i++) {
            var action = globalActions[i]
            if (actionMatches(action, queryLower)) list.push(action)
        }

        var trimmed = (queryText || "").trim()
        if (trimmed !== "") {
            list.unshift({
                entryType: "action",
                actionId: "web_search",
                name: "Search web",
                genericName: trimmed,
                icon: "edit-find",
                url: "https://duckduckgo.com/?q=" + encodeURIComponent(trimmed),
                keywords: "web search"
            })

            if (looksLikeMath(trimmed)) {
                list.unshift({
                    entryType: "action",
                    actionId: "calc_eval",
                    name: "Calculate and copy",
                    genericName: trimmed,
                    icon: "accessories-calculator",
                    expression: trimmed,
                    keywords: "calc evaluate"
                })
            }

            if (looksLikePath(trimmed)) {
                list.unshift({
                    entryType: "action",
                    actionId: "open_path",
                    name: "Open path",
                    genericName: trimmed,
                    icon: "folder-open",
                    path: trimmed,
                    keywords: "path open"
                })
            }
        }

        return limitEntries(list, maxEntries)
    }

    function buildObsidianEntries(queryText, queryLower) {
        var list = []
        var trimmed = (queryText || "").trim()

        if (trimmed !== "") {
            list.push({
                entryType: "action",
                actionId: "capture_inline",
                name: "Add quick note",
                genericName: trimmed,
                icon: "list-add",
                noteText: trimmed,
                keywords: "obsidian quick note"
            })
        }

        var filtered = []
        for (var i = 0; i < obsidianActions.length; i++) {
            var action = obsidianActions[i]
            if (actionMatches(action, queryLower)) filtered.push(action)
        }

        filtered.sort(function(a, b) {
            var aPrefix = lower(a.name).indexOf(queryLower) === 0
            var bPrefix = lower(b.name).indexOf(queryLower) === 0
            if (aPrefix !== bPrefix) return aPrefix ? -1 : 1

            return (a.name || "").localeCompare(b.name || "")
        })

        return limitEntries(list.concat(filtered), maxEntries)
    }

    function buildShellEntries(queryText) {
        var cmd = (queryText || "").trim()
        if (cmd === "") {
            return [{
                entryType: "action",
                actionId: "noop",
                name: "Run shell command",
                genericName: "Type command after > or !r",
                icon: "utilities-terminal",
                keywords: "run shell command"
            }]
        }

        return [{
            entryType: "action",
            actionId: "run_shell",
            name: "Run shell command",
            genericName: cmd,
            icon: "utilities-terminal",
            command: cmd,
            keywords: "run shell command"
        }]
    }

    function buildCalcEntries(queryText) {
        var expression = (queryText || "").trim()
        if (expression === "") {
            return [{
                entryType: "action",
                actionId: "noop",
                name: "Calculator",
                genericName: "Type expression after =",
                icon: "accessories-calculator",
                keywords: "calculator"
            }]
        }

        return [{
            entryType: "action",
            actionId: "calc_eval",
            name: "Calculate and copy",
            genericName: expression,
            icon: "accessories-calculator",
            expression: expression,
            keywords: "calculator evaluate"
        }]
    }

    function buildWebEntries(queryText) {
        var query = (queryText || "").trim()
        if (query === "") {
            return [{
                entryType: "action",
                actionId: "noop",
                name: "Web search",
                genericName: "Type query after ?",
                icon: "edit-find",
                keywords: "web search"
            }]
        }

        return [{
            entryType: "action",
            actionId: "web_search",
            name: "Search web",
            genericName: query,
            icon: "edit-find",
            url: "https://duckduckgo.com/?q=" + encodeURIComponent(query),
            keywords: "web search"
        }]
    }

    function buildCombiEntries(queryText, queryLower) {
        var merged = []

        var windows = buildWindowEntries(queryLower)
        var actions = buildActionEntries(queryText, queryLower)
        var apps = buildAppEntries(queryLower)

        var windowLimit = queryLower === "" ? 6 : 10
        var actionLimit = queryLower === "" ? 8 : 16

        appendLimited(merged, windows, windowLimit)
        appendLimited(merged, actions, windowLimit + actionLimit)
        appendLimited(merged, apps, maxEntries)

        return limitEntries(merged, maxEntries)
    }

    property var launcherEntries: {
        var state = queryState
        var mode = normalizeMode(state.mode)
        var queryText = state.query || ""
        var queryLower = lower(queryText)

        if (mode === "apps") return buildAppEntries(queryLower)
        if (mode === "windows") return buildWindowEntries(queryLower)
        if (mode === "actions") return buildActionEntries(queryText, queryLower)
        if (mode === "obsidian") return buildObsidianEntries(queryText, queryLower)
        if (mode === "shell") return buildShellEntries(queryText)
        if (mode === "calc") return buildCalcEntries(queryText)
        if (mode === "web") return buildWebEntries(queryText)

        return buildCombiEntries(queryText, queryLower)
    }

    Process {
        id: cmdProc
    }

    function runCommand(cmd) {
        cmdProc.command = ["bash", "-c", cmd]
        cmdProc.running = true
        hide()
    }

    function runAction(entry) {
        if (!entry || !entry.actionId) return

        switch (entry.actionId) {
        case "noop":
            return
        case "switch_mode_combi":
            openMode("combi", "")
            return
        case "switch_mode_apps":
            openMode("apps", "")
            return
        case "switch_mode_windows":
            openMode("windows", "")
            return
        case "switch_mode_actions":
            openMode("actions", "")
            return
        case "switch_mode_obsidian":
            openMode("obsidian", "")
            return
        case "open_terminal":
            runCommand("kitty")
            return
        case "open_browser":
            runCommand("zen-browser")
            return
        case "open_home_folder":
            runCommand("xdg-open \"$HOME\"")
            return
        case "lock_screen":
            runCommand("hyprlock")
            return
        case "session_menu":
            runCommand("qs ipc call session toggle")
            return
        case "reload_hypr":
            runCommand("hyprctl reload")
            return
        case "toggle_focus_mode":
            runCommand("\"$HOME/.config/hypr/UserScripts/FocusMode.sh\"")
            return
        case "open_vault":
            runCommand("obsidian-notes")
            return
        case "open_quick_capture":
            runCommand("xdg-open \"obsidian://open?vault=MainVault&file=00_Inbox%2FQuick%20Capture.md\"")
            return
        case "open_daily":
            runCommand("today=$(date +%F); daily_file=\"$HOME/Notes/MainVault/01_Daily/$today.md\"; if [ ! -f \"$daily_file\" ]; then printf '# %s - Daily\\n\\n## Focus\\n-\\n\\n## Notes\\n-\\n\\n## Tasks\\n- [ ]\\n\\n## Links\\n-\\n' \"$today\" > \"$daily_file\"; fi; xdg-open \"obsidian://open?vault=MainVault&file=01_Daily%2F$today.md\"")
            return
        case "open_vault_folder":
            runCommand("xdg-open \"$HOME/Notes/MainVault\"")
            return
        case "capture_inline":
            if ((entry.noteText || "").trim() === "") return
            runCommand("note " + shellQuote(entry.noteText))
            return
        case "run_shell":
            if ((entry.command || "").trim() === "") return
            runCommand(entry.command)
            return
        case "web_search":
            if ((entry.url || "").trim() === "") return
            runCommand("xdg-open " + shellQuote(entry.url))
            return
        case "calc_eval": {
            var expression = (entry.expression || "").trim()
            if (expression === "") return

            var calcCommand = "if command -v qalc >/dev/null 2>&1; then result=$(qalc -t " + shellQuote(expression) + " 2>/dev/null); elif command -v bc >/dev/null 2>&1; then result=$(printf '%s\\n' " + shellQuote(expression) + " | bc -l 2>/dev/null); else result=; fi; if [ -n \"$result\" ]; then printf '%s' \"$result\" | wl-copy; notify-send \"Calc\" \"$result\"; else notify-send \"Calc\" \"No result\"; fi"
            runCommand(calcCommand)
            return
        }
        case "open_path":
            if ((entry.path || "").trim() === "") return
            runCommand("xdg-open " + shellQuote(entry.path))
            return
        default:
            return
        }
    }

    function activateEntry(entry) {
        if (!entry) return

        if (entry.entryType === "action") {
            runAction(entry)
            return
        }

        if (entry.entryType === "window") {
            if (entry.windowRef && entry.windowRef.activate) entry.windowRef.activate()

            var titlePattern = ""
            var classPattern = ""

            if ((entry.windowTitle || "").trim() !== "") {
                titlePattern = "title:^" + escapeRegex((entry.windowTitle || "").trim()) + "$"
            }

            if ((entry.appIdExact || "").trim() !== "") {
                classPattern = "class:^" + escapeRegex((entry.appIdExact || "").trim()) + "$"
            }

            if (titlePattern !== "" || classPattern !== "") {
                var focusCmd = ""

                if (titlePattern !== "") {
                    focusCmd = "hyprctl dispatch focuswindow " + shellQuote(titlePattern) + " >/dev/null 2>&1"
                }

                if (classPattern !== "") {
                    if (focusCmd !== "") {
                        focusCmd += " || "
                    }
                    focusCmd += "hyprctl dispatch focuswindow " + shellQuote(classPattern) + " >/dev/null 2>&1"
                }

                runCommand(focusCmd)
                return
            }

            hide()
            return
        }

        if (entry.execute) {
            entry.execute()
            hide()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.visible && Hyprland.focusedMonitor?.name === modelData.name
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            contentItem {
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) root.hide()
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.hide()
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.1
                width: 900
                height: 620
                radius: 20
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.97)
                border.width: 1
                border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: 12
                        color: Colors.bgHighlight

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
                                text: ">"
                                font.family: Appearance.font.mono
                                font.pixelSize: 23
                                color: Colors.fgMuted
                                Layout.alignment: Qt.AlignVCenter
                                renderType: Text.NativeRendering
                                font.hintingPreference: Font.PreferFullHinting
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                font.family: Appearance.font.ui
                                font.pixelSize: 21
                                renderType: Text.NativeRendering
                                font.hintingPreference: Font.PreferFullHinting
                                color: Colors.fg
                                clip: true
                                focus: root.visible
                                onTextChanged: {
                                    root.searchText = text
                                    appList.currentIndex = 0
                                }

                                Connections {
                                    target: root
                                    function onVisibleChanged() {
                                        if (!root.visible) return

                                        if (root.searchCleared) {
                                            searchInput.text = ""
                                            root.searchCleared = false
                                        } else {
                                            searchInput.text = root.searchText
                                        }

                                        searchInput.cursorPosition = searchInput.text.length
                                        searchInput.forceActiveFocus()
                                    }
                                }

                                Keys.onPressed: event => {
                                    var ctrl = (event.modifiers & Qt.ControlModifier) !== 0

                                    if (ctrl && event.key === Qt.Key_1) {
                                        root.openMode("apps", "")
                                        event.accepted = true
                                        return
                                    }

                                    if (ctrl && event.key === Qt.Key_2) {
                                        root.openMode("combi", "")
                                        event.accepted = true
                                        return
                                    }

                                    if (ctrl && event.key === Qt.Key_3) {
                                        root.openMode("windows", "")
                                        event.accepted = true
                                        return
                                    }

                                    if (ctrl && event.key === Qt.Key_4) {
                                        root.openMode("actions", "")
                                        event.accepted = true
                                        return
                                    }

                                    if (ctrl && event.key === Qt.Key_5) {
                                        root.openMode("obsidian", "")
                                        event.accepted = true
                                        return
                                    }

                                }

                                Keys.onReturnPressed: {
                                    var idx = appList.currentIndex >= 0 ? appList.currentIndex : 0
                                    if (root.launcherEntries.length > idx) root.activateEntry(root.launcherEntries[idx])
                                }

                                Keys.onEscapePressed: root.hide()

                                Keys.onDownPressed: {
                                    var maxIndex = Math.max(root.launcherEntries.length - 1, 0)
                                    appList.currentIndex = Math.min(appList.currentIndex + 1, maxIndex)
                                }

                                Keys.onUpPressed: {
                                    var maxIndex = Math.max(root.launcherEntries.length - 1, 0)
                                    appList.currentIndex = Math.max(Math.min(appList.currentIndex - 1, maxIndex), 0)
                                }

                                Keys.onTabPressed: event => {
                                    var ctrl = (event.modifiers & Qt.ControlModifier) !== 0
                                    var shift = (event.modifiers & Qt.ShiftModifier) !== 0

                                    if (ctrl) {
                                        root.cycleBaseMode(shift ? -1 : 1)
                                        event.accepted = true
                                        return
                                    }

                                    var maxIndex = Math.max(root.launcherEntries.length - 1, 0)
                                    appList.currentIndex = Math.min(appList.currentIndex + 1, maxIndex)
                                }

                                Keys.onBacktabPressed: event => {
                                    var ctrl = (event.modifiers & Qt.ControlModifier) !== 0

                                    if (ctrl) {
                                        root.cycleBaseMode(-1)
                                        event.accepted = true
                                        return
                                    }

                                    var maxIndex = Math.max(root.launcherEntries.length - 1, 0)
                                    appList.currentIndex = Math.max(Math.min(appList.currentIndex - 1, maxIndex), 0)
                                }

                                Text {
                                    visible: searchInput.text === ""
                                    text: root.modePlaceholder(root.queryState.mode)
                                    font: searchInput.font
                                    color: Colors.fgMuted
                                }
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: root.modeChips

                            delegate: Rectangle {
                                required property var modelData
                                property bool chipActive: root.queryState.mode === modelData.id
                                property bool chipBase: root.baseMode === modelData.id

                                radius: 8
                                height: 34
                                width: chipRow.implicitWidth + 14
                                color: chipActive
                                       ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                                       : (chipBase
                                          ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.1)
                                          : Colors.bgHighlight)
                                border.width: 1
                                border.color: chipActive
                                       ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.35)
                                       : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)

                                RowLayout {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: modelData.label
                                        font.family: Appearance.font.ui
                                        font.pixelSize: 14
                                        color: Colors.fg
                                        renderType: Text.NativeRendering
                                        font.hintingPreference: Font.PreferFullHinting
                                    }

                                    Text {
                                        text: modelData.key
                                        font.family: Appearance.font.mono
                                        font.pixelSize: 11
                                        color: Colors.fgMuted
                                        renderType: Text.NativeRendering
                                        font.hintingPreference: Font.PreferFullHinting
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openMode(modelData.id, "")
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.modeHelp(root.queryState.mode)
                        font.family: Appearance.font.ui
                        font.pixelSize: 14
                        color: Colors.fgMuted
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                    }

                    ListView {
                        id: appList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        model: root.launcherEntries
                        currentIndex: 0
                        highlightFollowsCurrentItem: true
                        keyNavigationEnabled: false

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: appList.width
                            height: 58
                            radius: 10
                            color: (index === appList.currentIndex || entryMouseArea.containsMouse)
                                   ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
                                   : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                IconImage {
                                    source: Quickshell.iconPath(modelData.icon || "application-x-executable", true)
                                    implicitSize: 34
                                    smooth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: modelData.entryType === "window" && modelData.activated
                                              ? "* " + (modelData.name || "")
                                              : (modelData.name || "")
                                        font.family: Appearance.font.ui
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                        color: Colors.fg
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        renderType: Text.NativeRendering
                                        font.hintingPreference: Font.PreferFullHinting
                                    }

                                    Text {
                                        visible: (modelData.genericName || "") !== ""
                                        text: modelData.genericName || ""
                                        font.family: Appearance.font.ui
                                        font.pixelSize: 14
                                        color: Colors.fgMuted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        renderType: Text.NativeRendering
                                        font.hintingPreference: Font.PreferFullHinting
                                    }
                                }

                                Rectangle {
                                    radius: 6
                                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)
                                    border.width: 1
                                    border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
                                    implicitWidth: typeTag.implicitWidth + 10
                                    implicitHeight: typeTag.implicitHeight + 4

                                    Text {
                                        id: typeTag
                                        anchors.centerIn: parent
                                        text: modelData.entryType === "action"
                                              ? "act"
                                              : (modelData.entryType === "window" ? "win" : "app")
                                        font.family: Appearance.font.mono
                                        font.pixelSize: 11
                                        color: Colors.fgMuted
                                        renderType: Text.NativeRendering
                                        font.hintingPreference: Font.PreferFullHinting
                                    }
                                }
                            }

                            MouseArea {
                                id: entryMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activateEntry(modelData)
                            }
                        }
                    }

                    Text {
                        text: root.launcherEntries.length + " results" + " | mode: " + root.modeLabel(root.queryState.mode)
                        font.family: Appearance.font.ui
                        font.pixelSize: 14
                        color: Colors.fgMuted
                        Layout.alignment: Qt.AlignRight
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                    }
                }
            }
        }
    }
}
