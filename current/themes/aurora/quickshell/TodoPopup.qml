import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "services" as Svc

// Full task editor — replaces the read-only popup with a sudo-tiz-class UI:
// 4 tabs (Active / Today / Upcoming / Completed), search, stats strip, add &
// edit dialog, hover/lift animations, collapse-on-mutate, etc. All persistence
// goes through the TaskService singleton which wraps `vault-task` CLI.
Item {
    id: todo
    focus: true                     // accept keyboard input (Esc, shortcuts)

    signal closeRequested()         // bubbled up to PopupBase to set open=false

    // Theme tokens (passed in from PopupBase wrapper)
    property color accent: "#7aa8ff"
    property color fg: "#e6e6f0"
    property color fgDim: "#a5a9c2"
    property color fgMuted: "#6f7590"
    property color bgHighlight: "#3f4053"

    // Active tab: "active" | "today" | "upcoming" | "completed"
    property string activeTab: "today"
    property string searchQuery: ""

    function _todayIso() {
        var d = new Date()
        return d.getFullYear() + "-" +
               String(d.getMonth()+1).padStart(2, "0") + "-" +
               String(d.getDate()).padStart(2, "0")
    }

    // Reactive filtered list — re-evaluates whenever activeTab, searchQuery,
    // or any of the referenced TaskService properties change.
    readonly property var filteredTasks: {
        var pool = []
        // touch reactive deps so binding tracks them
        var todayList = Svc.TaskService.today
        var otherList = Svc.TaskService.other
        var completedList = Svc.TaskService.completed
        var todayIso = todo._todayIso()

        if (todo.activeTab === "today") {
            pool = todayList || []
        } else if (todo.activeTab === "upcoming") {
            pool = (otherList || []).filter(t => t.due && t.due > todayIso)
        } else if (todo.activeTab === "completed") {
            pool = completedList || []
        } else {
            pool = (todayList || []).concat(otherList || [])
        }

        var q = (todo.searchQuery || "").toLowerCase().trim()
        if (q !== "") {
            pool = pool.filter(function(t) {
                if ((t.text || "").toLowerCase().indexOf(q) >= 0) return true
                if ((t.categories || []).some(c => c.toLowerCase().indexOf(q) >= 0)) return true
                if ((t.priority || "").toLowerCase().indexOf(q) >= 0) return true
                return false
            })
        }
        return pool
    }

    readonly property var tabs: [
        { id: "active",    label: "Active" },
        { id: "today",     label: "Today" },
        { id: "upcoming",  label: "Upcoming" },
        { id: "completed", label: "Done" }
    ]

    function tabCount(id) {
        var s = Svc.TaskService.stats
        if (id === "today")     return s.todayCount
        if (id === "upcoming")  return s.upcomingCount
        if (id === "completed") return s.completedCount
        return s.totalActive
    }

    function _findTaskById(id) {
        var pool = Svc.TaskService.tasksToday()
                    .concat(Svc.TaskService.tasksOther())
                    .concat(Svc.TaskService.tasksCompleted())
        for (var i = 0; i < pool.length; i++) if (pool[i].id === id) return pool[i]
        return null
    }

    // ──────────────── Layout ────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Header — title + add + refresh
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Tasks"
                font.family: Appearance.font.ui
                font.pixelSize: 22
                font.weight: Font.Bold
                color: todo.fg
                renderType: Text.NativeRendering
            }
            Text {
                text: {
                    var s = Svc.TaskService.stats
                    return s.totalActive + " active · " +
                           s.todayCount + " today · " +
                           s.overdueCount + " overdue · " +
                           s.completionRate + "% done"
                }
                font.family: Appearance.font.ui
                font.pixelSize: 11
                color: todo.fgMuted
                Layout.alignment: Qt.AlignVCenter
                renderType: Text.NativeRendering
            }
            Item { Layout.fillWidth: true }

            // Refresh button
            Rectangle {
                Layout.preferredWidth: 28; Layout.preferredHeight: 28
                radius: 14
                color: refreshArea.containsMouse ? todo.bgHighlight : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "↻"
                    font.pixelSize: 16
                    color: todo.fgDim
                }
                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Svc.TaskService.refresh()
                }
            }

            // Add button
            Rectangle {
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                radius: 16
                color: todo.accent
                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    color: "white"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: editDialog.openForAdd()
                }
            }
        }

        // Tab bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: todo.tabs
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: todo.activeTab === modelData.id
                           ? Qt.rgba(todo.accent.r, todo.accent.g, todo.accent.b, 0.18)
                           : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: modelData.label
                            font.family: Appearance.font.ui
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: todo.activeTab === modelData.id ? todo.accent : todo.fgDim
                        }
                        Text {
                            text: todo.tabCount(modelData.id)
                            font.family: Appearance.font.mono
                            font.pixelSize: 10
                            color: todo.fgMuted
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: todo.activeTab = modelData.id
                    }
                }
            }
        }

        // Search bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 8
            color: todo.bgHighlight

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                Text {
                    text: "🔍"
                    font.pixelSize: 12
                    color: todo.fgMuted
                }
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search tasks, tags, priority…"
                    text: todo.searchQuery
                    onTextChanged: todo.searchQuery = text
                    font.family: Appearance.font.ui
                    font.pixelSize: 12
                    color: todo.fg
                    background: null
                    Keys.onEscapePressed: event => {
                        // Only swallow when there's text to clear; otherwise
                        // let the event bubble up so the parent closes the popup.
                        if (todo.searchQuery !== "") {
                            todo.searchQuery = ""; text = ""
                            event.accepted = true
                        } else {
                            todo.forceActiveFocus()
                            event.accepted = false
                        }
                    }
                }
                Text {
                    visible: todo.searchQuery !== ""
                    text: "✕"
                    font.pixelSize: 12
                    color: todo.fgMuted
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { todo.searchQuery = ""; searchField.text = "" }
                    }
                }
            }
        }

        // Body — task list
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: todo.filteredTasks

            delegate: TaskItem {
                required property var modelData
                required property int index
                task: modelData
                rowIndex: index
                accent: todo.accent
                fg: todo.fg
                fgDim: todo.fgDim
                fgMuted: todo.fgMuted
                bgHighlight: todo.bgHighlight
                onToggleRequested: id => Svc.TaskService.toggleTask(id)
                onDeleteRequested: id => Svc.TaskService.deleteTask(id)
                onEditRequested: id => {
                    var t = todo._findTaskById(id)
                    if (t) editDialog.openForEdit(t)
                }
            }

            // Empty state
            Rectangle {
                anchors.centerIn: parent
                visible: list.count === 0
                width: 200; height: 140
                color: "transparent"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 64; height: 64; radius: 32
                        color: Qt.rgba(todo.accent.r, todo.accent.g, todo.accent.b, 0.12)
                        Text {
                            anchors.centerIn: parent
                            text: todo.activeTab === "completed" ? "🎉" : "✓"
                            font.pixelSize: 28
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (todo.searchQuery !== "") return "No matches"
                            switch (todo.activeTab) {
                                case "today":     return "Nothing for today"
                                case "upcoming":  return "No upcoming tasks"
                                case "completed": return "Nothing done yet"
                                default:          return "All clear"
                            }
                        }
                        font.family: Appearance.font.ui
                        font.pixelSize: 13
                        color: todo.fgDim
                    }
                }
            }
        }

        // Footer
        Text {
            Layout.alignment: Qt.AlignRight
            text: Svc.TaskService.generatedAt !== ""
                  ? "Updated " + Svc.TaskService.generatedAt.substring(11, 16)
                  : ""
            font.family: Appearance.font.ui
            font.pixelSize: 10
            color: todo.fgMuted
        }
    }

    // Edit / add dialog overlay
    TaskEditDialog {
        id: editDialog
        accent: todo.accent
        fg: todo.fg
        fgDim: todo.fgDim
        fgMuted: todo.fgMuted
        bgHighlight: todo.bgHighlight
        onSubmitted: payload => {
            if (payload.editing) {
                Svc.TaskService.editTask(payload.id, {
                    text: payload.text,
                    time: payload.time,
                    endTime: payload.endTime,
                    due: payload.due,
                    priority: payload.priority,
                    recurring: payload.recurring,
                    categories: payload.categories,
                    description: payload.description,
                })
            } else {
                Svc.TaskService.addTask({
                    text: payload.text,
                    time: payload.time,
                    endTime: payload.endTime,
                    due: payload.due,
                    priority: payload.priority,
                    recurring: payload.recurring,
                    categories: payload.categories,
                    description: payload.description,
                    file: payload.file,
                })
            }
        }
    }

    // Keyboard shortcuts (active when popup has focus)
    Keys.onEscapePressed: event => {
        if (editDialog.visible) { editDialog.close(); event.accepted = true }
        else if (todo.searchQuery !== "" && searchField.activeFocus) {
            todo.searchQuery = ""; searchField.text = ""; event.accepted = true
        }
        else { todo.closeRequested(); event.accepted = true }
    }
    Keys.onPressed: event => {
        // Don't steal letters while typing in search/dialog inputs
        if (searchField.activeFocus || editDialog.visible) return

        if (event.key === Qt.Key_N) {
            editDialog.openForAdd(); event.accepted = true
        } else if (event.key === Qt.Key_Slash) {
            searchField.forceActiveFocus(); event.accepted = true
        } else if (event.key === Qt.Key_1) { todo.activeTab = "active";    event.accepted = true }
        else if (event.key === Qt.Key_2)   { todo.activeTab = "today";     event.accepted = true }
        else if (event.key === Qt.Key_3)   { todo.activeTab = "upcoming";  event.accepted = true }
        else if (event.key === Qt.Key_4)   { todo.activeTab = "completed"; event.accepted = true }
    }
}
