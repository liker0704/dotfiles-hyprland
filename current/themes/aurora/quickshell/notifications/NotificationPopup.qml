import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ".."

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            Colors { id: colors }
            visible: NotificationService.count > 0
            focusable: false
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            // Don't block clicks — only cover notification area
            anchors { top: true; left: true; right: true }
            implicitWidth: 420
            implicitHeight: notifCol.implicitHeight + 60


            ColumnLayout {
                id: notifCol
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 54 }
                width: 400; spacing: 10

                Repeater {
                    model: NotificationService.notifications

                    // Outer shadow layer
                    Item {
                        id: cardRoot
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: card.height + 4

                        // Shadow
                        RectangularShadow {
                            anchors.fill: card; radius: card.radius
                            blur: Appearance.shadow.medium; spread: 1
                            color: Qt.rgba(0, 0, 0, Appearance.shadow.opacity)
                            offset: Qt.vector2d(0, 3)
                        }

                        Rectangle {
                            id: card
                            width: parent.width
                            height: cardCol.childrenRect.height + 24
                            radius: Appearance.rounding.large
                            color: Qt.rgba(colors.bg.r, colors.bg.g, colors.bg.b, Appearance.notif.bgAlpha)
                            antialiasing: true
                            border.width: 1
                            border.color: cardRoot.modelData.urgency === NotificationUrgency.Critical
                                ? Qt.rgba(colors.error.r, colors.error.g, colors.error.b, 0.4)
                                : Qt.rgba(colors.fg.r, colors.fg.g, colors.fg.b, 0.06)

                            // Hover stops auto-dismiss
                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                onEntered: cardRoot.modelData.hovered = true
                                onExited: cardRoot.modelData.hovered = false
                            }

                            // Slide + fade in
                            opacity: 0
                            x: 40
                            Component.onCompleted: { opacity = 1; x = 0 }
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                            ColumnLayout {
                                id: cardCol
                                anchors { fill: parent; margins: 12 }
                                spacing: 6

                                // Header: icon + app name + time + close
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8

                                    // App icon
                                    Image {
                                        source: {
                                            var icon = cardRoot.modelData.appIcon
                                            if (!icon || icon === "") return ""
                                            if (icon.startsWith("/")) return icon
                                            return Quickshell.iconPath(icon, true) || ""
                                        }
                                        Layout.preferredWidth: 20; Layout.preferredHeight: 20
                                        fillMode: Image.PreserveAspectFit; smooth: true
                                        sourceSize.width: 20; sourceSize.height: 20
                                        visible: source != "" && cardRoot.modelData.appIcon !== ""
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: cardRoot.modelData.appName || "Notification"
                                        color: colors.fgMuted
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.weight: Font.Bold
                                        font.capitalization: Font.AllUppercase
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Close
                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: closeMA.containsMouse ? Qt.rgba(colors.error.r, colors.error.g, colors.error.b, 0.2) : "transparent"
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"; color: colors.fgMuted; font.pixelSize: 10
                                        }
                                        MouseArea {
                                            id: closeMA; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: cardRoot.modelData.dismiss()
                                        }
                                    }
                                }

                                // Summary (title)
                                Text {
                                    text: cardRoot.modelData.summary
                                    color: colors.fg
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; font.weight: Font.Bold
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                    visible: text !== ""
                                }

                                // Body
                                Text {
                                    text: cardRoot.modelData.body
                                    color: colors.fgDim
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                                    wrapMode: Text.Wrap; maximumLineCount: 5; elide: Text.ElideRight
                                    Layout.fillWidth: true; visible: text !== ""
                                    lineHeight: 1.3
                                    textFormat: Text.PlainText
                                }

                                // Image (if notification has one)
                                Image {
                                    visible: cardRoot.modelData.image !== ""
                                    source: cardRoot.modelData.image
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 120
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true

                                    // Rounded clip
                                    layer.enabled: true
                                    layer.effect: Item {}
                                }

                                // Action buttons
                                RowLayout {
                                    spacing: 6; Layout.fillWidth: true
                                    visible: cardRoot.modelData.actions.length > 0
                                    Layout.topMargin: 4

                                    Repeater {
                                        model: cardRoot.modelData.actions

                                        Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true; height: 30; radius: 10
                                            color: actionMA.containsMouse
                                                ? Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.2)
                                                : colors.bgHighlight

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.text; color: colors.accent
                                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.weight: Font.Bold
                                            }
                                            MouseArea {
                                                id: actionMA; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: cardRoot.modelData.invokeAction(modelData.identifier)
                                            }
                                        }
                                    }
                                }

                                // Progress bar (auto-dismiss timer)
                                Rectangle {
                                    Layout.fillWidth: true; height: 2; radius: 1
                                    color: colors.bgHighlight
                                    visible: cardRoot.modelData.urgency !== NotificationUrgency.Critical

                                    Rectangle {
                                        height: parent.height; width: parent.width; radius: 1
                                        color: colors.accent; opacity: 0.4

                                        SequentialAnimation on width {
                                            running: parent.visible
                                            PauseAnimation { duration: 100 }
                                            NumberAnimation { to: 0; duration: cardRoot.modelData.expireTimeout * 1000; easing.type: Easing.Linear }
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
