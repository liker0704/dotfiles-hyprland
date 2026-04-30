import QtQuick
import QtQuick.Layouts

// TaskItem — single delegate row for the task list.
// Animated collapse-then-mutate on done/delete (180ms) + hover lift.
// Emits requests up to the parent; doesn't talk to TaskService directly.
Item {
    id: root

    required property var task   // task object from TaskService
    required property int rowIndex

    // Theme tokens — passed from TodoPopup so we don't depend on parent scope
    property color accent: "#7aa8ff"
    property color fg: "#e6e6f0"
    property color fgDim: "#a5a9c2"
    property color fgMuted: "#6f7590"
    property color bgHighlight: "#3f4053"
    property color overdueColor: "#ff6b7a"

    signal toggleRequested(string id)
    signal deleteRequested(string id)
    signal editRequested(string id)

    property bool _hovered: false
    property bool _collapsing: false

    width: ListView.view ? ListView.view.width : parent.width
    implicitHeight: _collapsing ? 0 : (card.implicitHeight + 6)
    // Clip only during the collapse-then-mutate animation; at rest we leave
    // it off so the description hover-popover (which extends below the row)
    // can be drawn outside the row's bounds.
    clip: _collapsing

    // Note: don't bind root.y — ListView controls delegate positioning. Lift
    // visually via card.anchors.topMargin instead, which only moves the
    // child rect within its parent slot (no conflict with ListView).
    Behavior on implicitHeight {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Timer {
        id: collapseFinishTimer
        interval: 200
        onTriggered: {
            if (root._pendingAction === "toggle") root.toggleRequested(root.task.id)
            else if (root._pendingAction === "delete") root.deleteRequested(root.task.id)
            root._pendingAction = ""
            root._collapsing = false
        }
    }
    property string _pendingAction: ""

    function startCollapse(action) {
        if (root._collapsing) return
        root._pendingAction = action
        root._collapsing = true
        collapseFinishTimer.start()
    }

    function priorityColor(p) {
        if (p === "highest") return "#ff4d57"
        if (p === "high")    return "#ff8a3d"
        if (p === "medium")  return "#f1c40f"
        if (p === "low")     return "#5fbfff"
        if (p === "lowest")  return "#7a86b6"
        return root.bgHighlight
    }

    Rectangle {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root._hovered ? -1 : 0
        Behavior on anchors.topMargin {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
        radius: 10
        color: root._hovered
               ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)
               : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
        implicitHeight: row.implicitHeight + 14

        // Coloured left edge — priority for active, accent if today, dim if completed
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            radius: 2
            color: root.task.done       ? root.fgMuted
                 : root.task.overdue    ? root.overdueColor
                 : root.task.priority   ? root.priorityColor(root.task.priority)
                 : root.accent
            opacity: root.task.done ? 0.4 : 0.85
        }

        RowLayout {
            id: row
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            spacing: 10

            // Checkbox
            Rectangle {
                id: checkbox
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 2
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 11
                border.width: root.task.done ? 0 : 2
                border.color: root.task.done ? "transparent" : root.fgMuted
                color: root.task.done
                       ? root.accent
                       : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.0)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    visible: root.task.done
                    anchors.centerIn: parent
                    text: "✓"
                    color: "white"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    // Fire toggle immediately — the watcher refresh (~1s) provides
                    // its own visual feedback (strikethrough or disappear into
                    // completed tab). Animating the row first would just hide that.
                    onClicked: root.toggleRequested(root.task.id)
                }
            }

            // Body — text, meta row
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                // Title row — text + time pill
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Time pill (only when present)
                    Rectangle {
                        visible: (root.task.time || "") !== ""
                        radius: height / 2
                        height: timeText.implicitHeight + 6
                        implicitWidth: timeText.implicitWidth + 14
                        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: timeText
                            anchors.centerIn: parent
                            text: (root.task.end_time && root.task.end_time !== "")
                                  ? root.task.time + "–" + root.task.end_time
                                  : (root.task.time || "")
                            font.family: Appearance.font.mono
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.accent
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.task.text || ""
                        font.family: Appearance.font.ui
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: root.task.done ? root.fgMuted : root.fg
                        wrapMode: Text.Wrap
                        renderType: Text.NativeRendering
                        // Strikethrough when done
                        font.strikeout: root.task.done
                    }

                    // Delete (× hover only)
                    Text {
                        visible: root._hovered && !root.task.done
                        text: "✕"
                        font.pixelSize: 14
                        color: root.fgMuted
                        Layout.alignment: Qt.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startCollapse("delete")
                        }
                    }
                }

                // Meta row — due, priority dot, category chips, source path
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: dueChip.visible || prioChip.visible || catRow.visible || sourceText.visible || descIndicator.visible

                    // Due-date chip
                    Rectangle {
                        id: dueChip
                        visible: (root.task.due || "") !== ""
                        radius: height / 2
                        height: dueText.implicitHeight + 4
                        implicitWidth: dueText.implicitWidth + 12
                        color: root.task.overdue
                               ? Qt.rgba(root.overdueColor.r, root.overdueColor.g, root.overdueColor.b, 0.18)
                               : Qt.rgba(root.fgMuted.r, root.fgMuted.g, root.fgMuted.b, 0.18)
                        Text {
                            id: dueText
                            anchors.centerIn: parent
                            text: "📅 " + (root.task.due || "")
                            font.family: Appearance.font.mono
                            font.pixelSize: 10
                            color: root.task.overdue ? root.overdueColor : root.fgDim
                        }
                    }

                    // Priority chip
                    Rectangle {
                        id: prioChip
                        visible: (root.task.priority || "") !== ""
                        radius: height / 2
                        height: prioText.implicitHeight + 4
                        implicitWidth: prioText.implicitWidth + 10
                        color: Qt.rgba(root.priorityColor(root.task.priority).r,
                                       root.priorityColor(root.task.priority).g,
                                       root.priorityColor(root.task.priority).b, 0.18)
                        Text {
                            id: prioText
                            anchors.centerIn: parent
                            text: root.task.priority || ""
                            font.family: Appearance.font.ui
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: root.priorityColor(root.task.priority)
                        }
                    }

                    // Recurring badge
                    Text {
                        visible: (root.task.recurring || "") !== ""
                        text: "🔁 " + (root.task.recurring || "")
                        font.pixelSize: 10
                        color: root.fgMuted
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Description indicator (full text shown via ToolTip on hover)
                    Text {
                        id: descIndicator
                        visible: (root.task.description || "") !== ""
                        text: "📝"
                        font.pixelSize: 11
                        color: root.fgMuted
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Category chips
                    RowLayout {
                        id: catRow
                        spacing: 4
                        visible: (root.task.categories || []).length > 0
                        Repeater {
                            model: root.task.categories || []
                            Text {
                                required property string modelData
                                text: "#" + modelData
                                font.family: Appearance.font.ui
                                font.pixelSize: 10
                                color: root.accent
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Source file basename (faded)
                    Text {
                        id: sourceText
                        visible: (root.task.file || "") !== ""
                        text: root.task.file ? root.task.file.split("/").pop().replace(".md", "") : ""
                        font.family: Appearance.font.ui
                        font.pixelSize: 10
                        color: root.fgMuted
                        Layout.alignment: Qt.AlignRight
                        elide: Text.ElideRight
                        Layout.maximumWidth: 100
                    }
                }
            }
        }

        // Hover + right-click via Handlers — they don't intercept left clicks
        // so the checkbox/× MouseAreas inside still receive their events.
        HoverHandler {
            id: hoverHandler
            onHoveredChanged: root._hovered = hovered
        }
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: root.editRequested(root.task.id)
        }


        // Description hover-popover (custom — Qt Quick Controls' ToolTip
        // creates a separate window which doesn't render reliably inside a
        // Quickshell PopupWindow). 400 ms show delay so it isn't intrusive.
        Timer {
            id: descShowTimer
            interval: 400
            running: root._hovered && (root.task.description || "") !== ""
            onTriggered: descPopover.shown = true
            onRunningChanged: if (!running) descPopover.shown = false
        }
        Rectangle {
            id: descPopover
            property bool shown: false
            visible: shown
            anchors.left: card.left
            anchors.top: card.bottom
            anchors.topMargin: 4
            anchors.leftMargin: 14
            implicitWidth: Math.min(descTipText.implicitWidth + 20, 360)
            implicitHeight: descTipText.implicitHeight + 14
            radius: 8
            color: root.bgHighlight
            border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.25)
            border.width: 1
            z: 50
            opacity: shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Text {
                id: descTipText
                anchors.fill: parent
                anchors.margins: 10
                text: root.task.description || ""
                color: root.fg
                font.family: Appearance.font.ui
                font.pixelSize: 12
                wrapMode: Text.Wrap
                renderType: Text.NativeRendering
            }
        }
    }
}
