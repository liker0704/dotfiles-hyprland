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

    function toggle() { visible = !visible; searchText = "" }
    function hide() { visible = false; searchText = ""; searchCleared = true }
    property bool searchCleared: false

    IpcHandler {
        target: "launcher"
        function toggle() { root.toggle() }
    }

    property var filteredApps: {
        var apps = DesktopEntries.applications.values
        if (!apps) return []
        var list = []
        for (var i = 0; i < apps.length; i++) list.push(apps[i])

        if (searchText === "") {
            list.sort(function(a, b) { return a.name.localeCompare(b.name) })
            return list
        }

        var q = searchText.toLowerCase()
        var filtered = list.filter(function(e) {
            if ((e.name || "").toLowerCase().indexOf(q) >= 0) return true
            if ((e.genericName || "").toLowerCase().indexOf(q) >= 0) return true
            // Search keywords
            var kw = e.keywords || []
            for (var k = 0; k < kw.length; k++) {
                if (kw[k].toLowerCase().indexOf(q) >= 0) return true
            }
            // Search categories
            var cats = e.categories || []
            for (var c = 0; c < cats.length; c++) {
                if (cats[c].toLowerCase().indexOf(q) >= 0) return true
            }
            // Search description
            if ((e.comment || "").toLowerCase().indexOf(q) >= 0) return true
            return false
        })
        filtered.sort(function(a, b) {
            // Name match = highest priority
            var aName = (a.name || "").toLowerCase().indexOf(q) === 0
            var bName = (b.name || "").toLowerCase().indexOf(q) === 0
            if (aName !== bName) return aName ? -1 : 1
            // Name contains > keyword match
            var aHas = (a.name || "").toLowerCase().indexOf(q) >= 0
            var bHas = (b.name || "").toLowerCase().indexOf(q) >= 0
            if (aHas !== bHas) return aHas ? -1 : 1
            return a.name.localeCompare(b.name)
        })
        return filtered
    }

    Process { id: cmdProc }

    function launch(entry) {
        entry.execute()
        hide()
    }

    function runCommand(cmd) {
        cmdProc.command = ["bash", "-c", cmd]
        cmdProc.running = true
        hide()
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
            anchors { top: true; left: true; right: true; bottom: true }


            contentItem {
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) root.hide()
                }
            }

            // Dim background
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.5)
                MouseArea { anchors.fill: parent; onClicked: root.hide() }
            }

            // Launcher card
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: parent.height * 0.15
                width: 620; height: 420
                radius: 20
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.97)
                border.width: 1
                border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 12

                    // Search field
                    Rectangle {
                        Layout.fillWidth: true; height: 48; radius: 12
                        color: Colors.bgHighlight

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8

                            Text {
                                text: "󰍉"; font.family: Appearance.font.mono; font.pixelSize: 20
                                color: Colors.fgMuted; Layout.alignment: Qt.AlignVCenter
                                renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                                font.family: Appearance.font.ui; font.pixelSize: 18
                                renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting
                                color: Colors.fg
                                clip: true
                                focus: root.visible
                                onTextChanged: { root.searchText = text; appList.currentIndex = 0 }
                                Connections {
                                    target: root
                                    function onVisibleChanged() { if (root.visible) searchInput.text = "" }
                                }
                                Keys.onReturnPressed: {
                                    // Run as shell command ONLY when prefixed with > or !
                                    // (removed implicit "no-match → bash -c text" fallback —
                                    // too easy to accidentally run deletion/reboot commands).
                                    if (text.startsWith(">") || text.startsWith("!")) {
                                        root.runCommand(text.substring(1).trim())
                                        return
                                    }
                                    var idx = appList.currentIndex >= 0 ? appList.currentIndex : 0
                                    if (root.filteredApps.length > idx) root.launch(root.filteredApps[idx])
                                }
                                Keys.onEscapePressed: root.hide()
                                Keys.onDownPressed: appList.currentIndex = Math.min(appList.currentIndex + 1, root.filteredApps.length - 1)
                                Keys.onUpPressed: appList.currentIndex = Math.max(appList.currentIndex - 1, 0)
                                Keys.onTabPressed: appList.currentIndex = Math.min(appList.currentIndex + 1, root.filteredApps.length - 1)

                                Text {
                                    visible: searchInput.text === ""
                                    text: "Search apps..."
                                    font: searchInput.font
                                    color: Colors.fgMuted
                                }
                            }
                        }
                    }

                    // App list
                    ListView {
                        id: appList
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; spacing: 2
                        model: root.filteredApps
                        currentIndex: 0
                        highlightFollowsCurrentItem: true
                        keyNavigationEnabled: false

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: appList.width; height: 48; radius: 10
                            color: (index === appList.currentIndex || appMA.containsMouse) ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12) : "transparent"

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10

                                IconImage {
                                    source: Quickshell.iconPath(modelData.icon, true)
                                    implicitSize: 32
                                    smooth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    spacing: 0; Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        text: modelData.name
                                        font.family: Appearance.font.ui; font.pixelSize: 16; font.weight: Font.Bold
                                        color: Colors.fg; elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting
                                    }
                                    Text {
                                        visible: (modelData.genericName || "") !== ""
                                        text: modelData.genericName || ""
                                        font.family: Appearance.font.ui; font.pixelSize: 13
                                        color: Colors.fgMuted; elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting
                                    }
                                }
                            }

                            MouseArea {
                                id: appMA; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.launch(modelData)
                            }
                        }
                    }

                    // Count
                    Text {
                        text: root.filteredApps.length + " apps"
                        font.family: Appearance.font.ui; font.pixelSize: 13
                        color: Colors.fgMuted; Layout.alignment: Qt.AlignRight
                        renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting
                    }
                }
            }
        }
    }
}
