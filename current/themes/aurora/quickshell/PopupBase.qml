import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    visible: false

    required property var barWindow
    property Item anchorItem: null
    property int popupWidth: 300
    property int popupHeight: 280
    property int popupX: -1
    property bool open: false

    property color bgColor: "#1e1e2e"
    property color borderColor: Qt.rgba(1, 1, 1, 0.06)

    default property alias content: contentContainer.data

    function toggle() { open = !open }

    HyprlandFocusGrab {
        windows: [popup]
        active: root.open
        onCleared: root.open = false
    }

    PopupWindow {
        id: popup
        visible: root.open
        anchor.window: root.barWindow
        anchor.rect.x: {
            if (root.popupX !== -1) return root.popupX
            if (!root.anchorItem) return 0
            var totalX = 0; var item = root.anchorItem
            while (item && item !== root.barWindow) { totalX += item.x; item = item.parent }
            return totalX + root.anchorItem.width / 2 - root.popupWidth / 2
        }
        anchor.rect.y: root.barWindow ? root.barWindow.implicitHeight + root.barWindow.margins.top + 6 : 44
        implicitWidth: root.popupWidth
        implicitHeight: root.popupHeight
        color: "transparent"

        // Shadow
        RectangularShadow {
            anchors.fill: popupBg
            radius: popupBg.radius
            blur: Appearance.shadow.medium
            spread: 1
            color: Qt.rgba(0, 0, 0, Appearance.shadow.opacity)
            offset: Qt.vector2d(0, 3)
        }

        Rectangle {
            id: popupBg
            anchors.fill: parent
            radius: Appearance.rounding.large
            color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, Appearance.popup.bgAlpha)
            border.width: 1
            border.color: root.borderColor
            antialiasing: true

            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.96

            Behavior on opacity { NumberAnimation { duration: Appearance.anim.fast; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: Appearance.anim.normal; easing.type: Easing.OutCubic } }

            Item {
                id: contentContainer
                anchors.fill: parent
                anchors.margins: Appearance.popup.padding
            }
        }
    }
}
