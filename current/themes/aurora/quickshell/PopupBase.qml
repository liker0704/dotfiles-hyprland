import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    visible: false

    required property var barWindow
    property Item anchorItem: null
    property int popupWidth: 300
    property int popupHeight: 280
    property int popupX: -1  // -1 = auto from anchorItem
    property bool open: false

    // Colors from parent (Bar passes these)
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
            // Walk up parent chain to sum x offsets
            var totalX = 0
            var item = root.anchorItem
            while (item && item !== root.barWindow) {
                totalX += item.x
                item = item.parent
            }
            return totalX + root.anchorItem.width / 2 - root.popupWidth / 2
        }
        // Y = bar height + bar top margin + gap
        anchor.rect.y: root.barWindow ? root.barWindow.implicitHeight + root.barWindow.margins.top + 6 : 44
        implicitWidth: root.popupWidth
        implicitHeight: root.popupHeight
        color: "transparent"

        Rectangle {
            id: popupBg
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(root.bgColor.r, root.bgColor.g, root.bgColor.b, 0.97)
            border.width: 1
            border.color: root.borderColor

            opacity: root.open ? 1 : 0
            transform: Translate { y: root.open ? 0 : -6 }

            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            Item {
                id: contentContainer
                anchors.fill: parent
                anchors.margins: 14
            }
        }
    }
}
