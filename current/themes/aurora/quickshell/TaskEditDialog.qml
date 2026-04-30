import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Modal sheet for adding or editing a task. Uses TaskService for persistence.
// Open via .openForAdd() or .openForEdit(taskObject). Submit fires
// addTask/editTask on TaskService and hides itself.
Item {
    id: dialog
    anchors.fill: parent
    visible: false
    z: 100

    // Theme tokens
    property color accent: "#7aa8ff"
    property color fg: "#e6e6f0"
    property color fgDim: "#a5a9c2"
    property color fgMuted: "#6f7590"
    property color bgHighlight: "#3f4053"
    property color bgPanel: "#1a1b26"

    // State
    property bool editing: false
    property string editingId: ""

    // Form fields
    property string fText: ""
    property string fTime: ""
    property string fEndTime: ""
    property string fDue: ""
    property string fPriority: ""        // "" | low | medium | high
    property string fRecurring: ""       // "" | daily | weekly | monthly | yearly
    property string fCategories: ""      // comma-separated
    property string fDescription: ""     // free-form notes; synced to GCal
    property string fFile: "today"

    signal submitted(var payload)        // emitted with the populated form

    function _reset() {
        editing = false; editingId = ""
        fText = ""; fTime = ""; fEndTime = ""; fDue = ""
        fPriority = ""; fRecurring = ""; fCategories = ""
        fDescription = ""
        fFile = "today"
    }

    function openForAdd() {
        _reset()
        visible = true
        Qt.callLater(function() { textField.forceActiveFocus() })
    }

    function openForEdit(t) {
        _reset()
        editing = true
        editingId = t.id || ""
        fText = t.text || ""
        fTime = t.time || ""
        fEndTime = t.end_time || ""
        fDue = t.due || ""
        fPriority = t.priority || ""
        fRecurring = t.recurring || ""
        fCategories = (t.categories || []).join(",")
        fDescription = t.description || ""
        visible = true
        Qt.callLater(function() { textField.forceActiveFocus() })
    }

    function close() {
        visible = false
        // Hand focus back to the parent (TodoPopup root) so its Keys.onEscapePressed
        // remains reachable for the next Esc press.
        if (dialog.parent) dialog.parent.forceActiveFocus()
    }

    function submit() {
        if (fText.trim() === "") return
        // Vault is single-line; collapse user-entered newlines into spaces.
        var description = fDescription.replace(/\s*\n+\s*/g, " ").trim()
        var payload = {
            id: editingId,
            text: fText.trim(),
            time: fTime.trim(),
            endTime: fEndTime.trim(),
            due: fDue.trim(),
            priority: fPriority,
            recurring: fRecurring,
            categories: fCategories.split(",").map(c => c.trim()).filter(c => c.length > 0),
            description: description,
            file: fFile,
            editing: editing,
        }
        dialog.submitted(payload)
        close()
    }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        MouseArea { anchors.fill: parent; onClicked: dialog.close() }
    }

    // Sheet
    Rectangle {
        id: sheet
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 460)
        implicitHeight: contentCol.implicitHeight + 36
        radius: 16
        color: dialog.bgPanel
        border.width: 1
        border.color: Qt.rgba(dialog.fg.r, dialog.fg.g, dialog.fg.b, 0.08)

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        opacity: dialog.visible ? 1 : 0
        scale:   dialog.visible ? 1 : 0.96

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Text {
                text: dialog.editing ? "Edit task" : "New task"
                font.family: Appearance.font.ui
                font.pixelSize: 18
                font.weight: Font.Bold
                color: dialog.fg
            }

            TextField {
                id: textField
                Layout.fillWidth: true
                placeholderText: "What needs to be done?"
                text: dialog.fText
                onTextChanged: dialog.fText = text
                font.family: Appearance.font.ui
                font.pixelSize: 14
                color: dialog.fg
                background: Rectangle {
                    color: dialog.bgHighlight
                    radius: 8
                    border.width: textField.activeFocus ? 1 : 0
                    border.color: dialog.accent
                }
                leftPadding: 12; rightPadding: 12; topPadding: 10; bottomPadding: 10
                Keys.onReturnPressed: dialog.submit()
                Keys.onEscapePressed: dialog.close()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Start time"; font.family: Appearance.font.ui; font.pixelSize: 11; color: dialog.fgMuted }
                    TextField {
                        Layout.fillWidth: true
                        placeholderText: "HH:MM"
                        text: dialog.fTime
                        onTextChanged: dialog.fTime = text
                        font.family: Appearance.font.mono
                        font.pixelSize: 13
                        color: dialog.fg
                        background: Rectangle { color: dialog.bgHighlight; radius: 6 }
                        leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "End time"; font.family: Appearance.font.ui; font.pixelSize: 11; color: dialog.fgMuted }
                    TextField {
                        Layout.fillWidth: true
                        placeholderText: "HH:MM"
                        text: dialog.fEndTime
                        onTextChanged: dialog.fEndTime = text
                        font.family: Appearance.font.mono
                        font.pixelSize: 13
                        color: dialog.fg
                        background: Rectangle { color: dialog.bgHighlight; radius: 6 }
                        leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Due date"; font.family: Appearance.font.ui; font.pixelSize: 11; color: dialog.fgMuted }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD or DD.MM.YYYY"
                    text: dialog.fDue
                    onTextChanged: dialog.fDue = text
                    font.family: Appearance.font.mono
                    font.pixelSize: 13
                    color: dialog.fg
                    background: Rectangle { color: dialog.bgHighlight; radius: 6 }
                    leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Priority"; font.family: Appearance.font.ui; font.pixelSize: 11; color: dialog.fgMuted }
                    ComboBox {
                        id: priorityBox
                        Layout.fillWidth: true
                        model: ["", "low", "medium", "high"]
                        currentIndex: Math.max(0, model.indexOf(dialog.fPriority))
                        onCurrentTextChanged: dialog.fPriority = currentText
                        font.family: Appearance.font.ui
                        font.pixelSize: 13
                        background: Rectangle { color: dialog.bgHighlight; radius: 6 }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Recurring"; font.family: Appearance.font.ui; font.pixelSize: 11; color: dialog.fgMuted }
                    ComboBox {
                        id: recurBox
                        Layout.fillWidth: true
                        model: ["", "daily", "weekly", "monthly", "yearly"]
                        currentIndex: Math.max(0, model.indexOf(dialog.fRecurring))
                        onCurrentTextChanged: dialog.fRecurring = currentText
                        font.family: Appearance.font.ui
                        font.pixelSize: 13
                        background: Rectangle { color: dialog.bgHighlight; radius: 6 }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Tags (comma-separated)"; font.family: Appearance.font.ui; font.pixelSize: 11; color: dialog.fgMuted }
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "project, urgent"
                    text: dialog.fCategories
                    onTextChanged: dialog.fCategories = text
                    font.family: Appearance.font.ui
                    font.pixelSize: 13
                    color: dialog.fg
                    background: Rectangle { color: dialog.bgHighlight; radius: 6 }
                    leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Description"; font.family: Appearance.font.ui; font.pixelSize: 11; color: dialog.fgMuted }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    background: Rectangle { color: dialog.bgHighlight; radius: 6 }
                    TextArea {
                        wrapMode: TextArea.Wrap
                        placeholderText: "Optional notes — synced to GCal description"
                        text: dialog.fDescription
                        onTextChanged: dialog.fDescription = text
                        font.family: Appearance.font.ui
                        font.pixelSize: 13
                        color: dialog.fg
                        background: null
                        leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                    }
                }
            }

            ColumnLayout {
                visible: !dialog.editing
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Add to"; font.family: Appearance.font.ui; font.pixelSize: 11; color: dialog.fgMuted }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["today", "00_Inbox/Quick Capture.md"]
                    currentIndex: Math.max(0, model.indexOf(dialog.fFile))
                    onCurrentTextChanged: dialog.fFile = currentText
                    font.family: Appearance.font.ui
                    font.pixelSize: 13
                    background: Rectangle { color: dialog.bgHighlight; radius: 6 }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Item { Layout.fillWidth: true }
                Button {
                    text: "Cancel"
                    onClicked: dialog.close()
                    background: Rectangle { color: dialog.bgHighlight; radius: 8 }
                    contentItem: Text {
                        text: parent.text
                        font.family: Appearance.font.ui
                        font.pixelSize: 13
                        color: dialog.fgDim
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 36
                }
                Button {
                    text: dialog.editing ? "Save" : "Add"
                    enabled: dialog.fText.trim() !== ""
                    onClicked: dialog.submit()
                    background: Rectangle {
                        color: parent.enabled ? dialog.accent : Qt.rgba(dialog.accent.r, dialog.accent.g, dialog.accent.b, 0.4)
                        radius: 8
                    }
                    contentItem: Text {
                        text: parent.text
                        font.family: Appearance.font.ui
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 36
                }
            }
        }
    }
}
