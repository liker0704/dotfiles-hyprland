import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

Scope {
    id: root
    property bool visible: false

    function toggle() { visible = !visible }
    function hide() { visible = false }

    IpcHandler {
        target: "session"
        function toggle() { root.toggle() }
    }

    readonly property var actions: [
        { icon: "󰌾", label: "Lock",      key: Qt.Key_L, cmd: "loginctl lock-session" },
        { icon: "󰗼", label: "Logout",    key: Qt.Key_E, cmd: "hyprctl dispatch exit" },
        { icon: "󰤄", label: "Suspend",   key: Qt.Key_U, cmd: "systemctl suspend" },
        { icon: "󰋊", label: "Hibernate", key: Qt.Key_H, cmd: "systemctl hibernate" },
        { icon: "󰜉", label: "Reboot",    key: Qt.Key_R, cmd: "systemctl reboot" },
        { icon: "󰐥", label: "Shutdown",  key: Qt.Key_S, cmd: "systemctl poweroff" }
    ]

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
            anchors { top: true; left: true; right: true; bottom: true }


            contentItem {
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) { root.hide(); return }
                    if (event.modifiers !== Qt.NoModifier) return
                    for (var i = 0; i < root.actions.length; i++) {
                        if (event.key === root.actions[i].key) {
                            execAction(root.actions[i].cmd)
                            return
                        }
                    }
                }
            }

            function execAction(cmd) {
                actionProc.command = ["bash", "-c", cmd]
                actionProc.running = true
                root.hide()
            }

            Process { id: actionProc }

            // Dim background
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.6)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.hide()
                }

                // Button grid
                GridLayout {
                    anchors.centerIn: parent
                    columns: 3; rowSpacing: 20; columnSpacing: 20

                    Repeater {
                        model: root.actions

                        Rectangle {
                            required property var modelData
                            required property int index

                            Layout.preferredWidth: 140; Layout.preferredHeight: 140
                            radius: 20
                            color: btnMA.containsMouse
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)
                                : Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.85)
                            border.width: 1
                            border.color: btnMA.containsMouse
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)
                                : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 12

                                Text {
                                    text: modelData.icon
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 36
                                    color: btnMA.containsMouse ? Colors.accent : Colors.fg
                                    Layout.alignment: Qt.AlignHCenter
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Text {
                                    text: modelData.label
                                    font.family: Appearance.font.ui; font.pixelSize: 13; font.weight: Font.Bold
                                    color: btnMA.containsMouse ? Colors.accent : Colors.fgDim
                                    Layout.alignment: Qt.AlignHCenter
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                Text {
                                    text: String.fromCharCode(modelData.key).toUpperCase()
                                    font.family: Appearance.font.ui; font.pixelSize: 10
                                    color: Colors.fgMuted; Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: btnMA; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: execAction(modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }
}
