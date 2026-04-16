import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Rectangle {
    id: root

    required property var context
    color: Qt.rgba(colors.bg.r, colors.bg.g, colors.bg.b, 1.0)

    Colors { id: colors }

    // Clock
    property string timeStr: ""
    property string dateStr: ""
    Timer {
        running: true; repeat: true; interval: 1000
        onTriggered: {
            var d = new Date()
            root.timeStr = d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
            root.dateStr = Qt.formatDate(d, "dddd, d MMMM")
        }
    }
    Component.onCompleted: {
        var d = new Date()
        timeStr = d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
        dateStr = Qt.formatDate(d, "dddd, d MMMM")
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        // Time
        Text {
            text: root.timeStr
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 80; font.weight: Font.Bold
            color: colors.fg
            Layout.alignment: Qt.AlignHCenter
        }

        // Date
        Text {
            text: root.dateStr
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
            color: colors.fgDim
            Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.preferredHeight: 30 }

        // Password field
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 320; height: 48; radius: 24
            color: colors.bgHighlight
            border.width: root.context.showFailure ? 2 : 1
            border.color: root.context.showFailure
                ? colors.error
                : (passwordInput.activeFocus ? colors.accent : Qt.rgba(colors.fg.r, colors.fg.g, colors.fg.b, 0.1))

            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 10

                Text {
                    text: root.context.unlockInProgress ? "󰑐" : "󰌾"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                    color: root.context.showFailure ? colors.error : colors.fgMuted
                    Layout.alignment: Qt.AlignVCenter
                }

                TextInput {
                    id: passwordInput
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                    color: colors.fg
                    echoMode: TextInput.Password
                    focus: true
                    enabled: !root.context.unlockInProgress
                    inputMethodHints: Qt.ImhSensitiveData
                    clip: true

                    onTextChanged: root.context.currentText = text
                    onAccepted: root.context.tryUnlock()

                    Connections {
                        target: root.context
                        function onCurrentTextChanged() { passwordInput.text = root.context.currentText }
                    }

                    Text {
                        visible: passwordInput.text === "" && !passwordInput.activeFocus
                        text: "Password"
                        font: passwordInput.font; color: colors.fgMuted
                    }
                }
            }
        }

        // Error message
        Text {
            visible: root.context.showFailure
            text: "Incorrect password"
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
            color: colors.error
            Layout.alignment: Qt.AlignHCenter
        }

        // Unlock button
        Rectangle {
            visible: root.context.currentText !== ""
            Layout.alignment: Qt.AlignHCenter
            width: 120; height: 36; radius: 18
            color: unlockMA.containsMouse
                ? Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.3)
                : Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.15)
            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                anchors.centerIn: parent
                text: root.context.unlockInProgress ? "Unlocking..." : "Unlock"
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.weight: Font.Bold
                color: colors.accent
            }
            MouseArea {
                id: unlockMA; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !root.context.unlockInProgress
                onClicked: root.context.tryUnlock()
            }
        }
    }
}
