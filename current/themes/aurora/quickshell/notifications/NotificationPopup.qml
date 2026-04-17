import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ".."

Scope {
    id: root
    property var theme: Theme {}

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: NotificationService.count > 0
            focusable: false
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            // Anchor top only: compositor sizes layer to implicitWidth (420)
            // and centers it. With left+right anchored the layer spanned the
            // full screen width and swallowed clicks on the whole top strip.
            anchors { top: true }
            implicitWidth: 420
            implicitHeight: notifCol.implicitHeight + 60

            ColumnLayout {
                id: notifCol
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 50 }
                width: 390; spacing: 8

                Repeater {
                    model: NotificationService.notifications

                    Item {
                        id: cardRoot
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: card.height

                        Rectangle {
                            id: card
                            width: parent.width
                            height: cardCol.implicitHeight + 24
                            radius: 16
                            color: root.theme.bg
                            border.width: 1
                            border.color: cardRoot.modelData.urgency === NotificationUrgency.Critical
                                ? root.theme.borderCritical : root.theme.border
                            antialiasing: true

                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                onEntered: cardRoot.modelData.hovered = true
                                onExited: cardRoot.modelData.hovered = false
                            }

                            opacity: 0; x: 30
                            Component.onCompleted: { opacity = 1; x = 0 }
                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                            ColumnLayout {
                                id: cardCol
                                anchors { fill: parent; margins: 12 }
                                spacing: 4

                                // Header
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 6
                                    Image {
                                        source: {
                                            var icon = cardRoot.modelData.appIcon
                                            if (!icon || icon === "") return ""
                                            if (icon.startsWith("/")) return icon
                                            return Quickshell.iconPath(icon, true) || ""
                                        }
                                        Layout.preferredWidth: 18; Layout.preferredHeight: 18
                                        fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true
                                        sourceSize.width: 64; sourceSize.height: 64
                                        visible: source != "" && cardRoot.modelData.appIcon !== ""
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                    Text {
                                        text: cardRoot.modelData.appName || "Notification"
                                        color: root.theme.fgMuted
                                        font.family: Appearance.font.ui; font.pixelSize: 12
                                        font.capitalization: Font.AllUppercase
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        width: 18; height: 18; radius: 9
                                        color: closeMA.containsMouse ? Qt.rgba(root.theme.error.r, root.theme.error.g, root.theme.error.b, 0.2) : "transparent"
                                        Text { anchors.centerIn: parent; text: "✕"; color: root.theme.fgMuted; font.pixelSize: 10 }
                                        MouseArea { id: closeMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cardRoot.modelData.dismiss() }
                                    }
                                }

                                // Title
                                Text {
                                    text: cardRoot.modelData.summary; color: root.theme.fg
                                    font.family: Appearance.font.ui; font.pixelSize: 17; font.weight: Font.Bold
                                    elide: Text.ElideRight; Layout.fillWidth: true; visible: text !== ""
                                }

                                // Body
                                Text {
                                    text: cardRoot.modelData.body; color: root.theme.fgDim
                                    font.family: Appearance.font.ui; font.pixelSize: 14
                                    wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight
                                    Layout.fillWidth: true; visible: text !== ""; lineHeight: 1.2
                                }

                                // Actions
                                RowLayout {
                                    spacing: 4; Layout.fillWidth: true; visible: cardRoot.modelData.actions.length > 0
                                    Repeater {
                                        model: cardRoot.modelData.actions
                                        Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true; height: 28; radius: 8
                                            color: actMA.containsMouse ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.2) : root.theme.bgHighlight
                                            Text { anchors.centerIn: parent; text: modelData.text; color: root.theme.accent; font.family: Appearance.font.ui; font.pixelSize: 12; font.weight: Font.Bold }
                                            MouseArea { id: actMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cardRoot.modelData.invokeAction(modelData.identifier) }
                                        }
                                    }
                                }

                                // Progress bar
                                Rectangle {
                                    Layout.fillWidth: true; height: 2; radius: 1; color: root.theme.bgHighlight
                                    visible: cardRoot.modelData.urgency !== NotificationUrgency.Critical
                                    Rectangle {
                                        height: parent.height; width: parent.width; radius: 1; color: root.theme.accent; opacity: 0.4
                                        SequentialAnimation on width {
                                            running: parent.visible
                                            PauseAnimation { duration: 50 }
                                            NumberAnimation { to: 0; duration: cardRoot.modelData.expireTimeout * 1000 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
