import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 40
    margins.top: 3
    margins.left: 6
    margins.right: 6
    color: "transparent"

    property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    property real pillHeight: bar.height - 6

    // --- Data sources ---
    FileView { id: batCapacity; path: "/sys/class/power_supply/BAT0/capacity"; watchChanges: true }
    FileView { id: batStatus; path: "/sys/class/power_supply/BAT0/status"; watchChanges: true }
    property int batteryPercent: parseInt(batCapacity.text()) || 0
    property bool batteryCharging: (batStatus.text().trim() === "Charging")

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    property real volumeRaw: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    property int volumePercent: Math.round(volumeRaw * 100)
    property bool volumeMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    property string networkName: ""
    property string networkType: ""
    property bool networkConnected: false
    Timer { interval: 30000; running: true; repeat: true; onTriggered: netProc.running = true }
    Process {
        id: netProc; running: true
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION d | grep connected | head -1"]
        stdout: SplitParser { onRead: data => {
            var parts = data.trim().split(":")
            bar.networkConnected = parts.length >= 2 && parts[1] === "connected"
            bar.networkType = parts.length >= 1 ? parts[0] : ""
            bar.networkName = bar.networkType === "wifi" ? (parts.length >= 3 ? parts[2] : "") : ""
        }}
    }

    property var mediaPlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property string mediaTrack: mediaPlayer ? (mediaPlayer.trackTitle || "") : ""
    property bool mediaPlaying: mediaPlayer ? mediaPlayer.playbackState === MprisPlaybackState.Playing : false
    property bool mediaAvailable: mediaTrack.length > 0

    property string timeStr: Qt.formatDateTime(new Date(), "h:mm AP")
    Timer {
        interval: 60000 - (Date.now() % 60000)
        running: true; repeat: true
        onTriggered: {
            interval = 60000
            var s = Qt.formatDateTime(new Date(), "h:mm AP")
            if (s !== bar.timeStr) bar.timeStr = s
        }
    }

    component Sep: Rectangle {
        width: 1; Layout.preferredHeight: 14; radius: 1
        color: Colors.fgMuted; opacity: 0.25; Layout.alignment: Qt.AlignVCenter
    }

    // ==================== CLOCK (absolute center) ====================
    Rectangle {
        id: clockPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: clockText.implicitWidth + 26; height: pillHeight; radius: height / 2
        color: Md3.md3.surface_container
        Text {
            id: clockText; anchors.centerIn: parent; text: bar.timeStr
            font.family: Appearance.font.ui; font.pixelSize: 15; font.weight: Font.DemiBold; color: Colors.fg
            renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: calendarPopup.toggle() }
    }

    // Calendar popup — centered under clock (clock is horizontalCenter of bar)
    PopupBase {
        id: calendarPopup; barWindow: bar; anchorItem: clockPill
        popupWidth: 280; popupHeight: 290
        bgColor: Md3.md3.surface_container_high; borderColor: Md3.md3.outline_variant
        CalendarPopup { anchors.fill: parent; accent: Md3.md3.primary; fg: Colors.fg; fgDim: Colors.fgDim; fgMuted: Colors.fgMuted; bgHighlight: Md3.md3.surface_container_highest }
    }

    // ==================== LEFT SECTION ====================
    RowLayout {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Workspaces
        Rectangle {
            color: Md3.md3.surface_container; radius: height / 2
            height: pillHeight; implicitWidth: wsRow.implicitWidth + 16

            RowLayout {
                id: wsRow; anchors.centerIn: parent; spacing: 5
                Repeater {
                    model: {
                        var ws = Hyprland.workspaces.values; var f = []
                        for (var i = 0; i < ws.length; i++) { if (ws[i].id > 0) f.push(ws[i]) }
                        f.sort(function(a, b) { return a.id - b.id }); return f
                    }
                    Rectangle {
                        required property var modelData
                        property bool isActive: modelData.id === bar.monitor.activeWorkspace?.id
                        Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 9
                        color: isActive ? Md3.md3.primary : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent; text: modelData.id.toString()
                            font.family: Appearance.font.ui; font.pixelSize: 14; font.weight: Font.Bold
                            font.letterSpacing: 0.6
                            color: parent.isActive ? Md3.md3.on_primary : Colors.fgMuted
                            renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Hyprland.dispatch("workspace " + modelData.id) }
                    }
                }
            }
        }

    }

    // ==================== RIGHT SECTION ====================
    RowLayout {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Tray (no background, LEFT of status pill, hide bluetooth)
        Repeater {
            model: SystemTray.items
            Item {
                required property var modelData
                visible: modelData.id.indexOf("blueman") === -1 && modelData.id.indexOf("bluetooth") === -1
                Layout.preferredWidth: visible ? 22 : 0; Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.centerIn: parent
                    width: 20; height: 20
                    source: modelData.icon
                    fillMode: Image.PreserveAspectFit
                    smooth: true; mipmap: true
                    sourceSize.width: 128; sourceSize.height: 128
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(event) {
                        if (event.button === Qt.RightButton) {
                            if (modelData.hasMenu) {
                                var p = trayMouse.mapToItem(null, event.x, event.y)
                                modelData.display(bar, p.x, p.y)
                            }
                        } else {
                            modelData.activate()
                        }
                    }
                }
            }
        }

        // Status pill
        Rectangle {
            color: Md3.md3.surface_container; radius: height / 2
            height: pillHeight; implicitWidth: statusRow.implicitWidth + 28

            RowLayout {
                id: statusRow; anchors.centerIn: parent; spacing: 10

                // Volume (click = popup, scroll = volume)
                RowLayout {
                    id: volumeArea
                    spacing: 4; Layout.alignment: Qt.AlignVCenter
                    Text { text: bar.volumeMuted ? "󰝟" : "󰕾"; font.family: Appearance.font.mono; font.pixelSize: 16; color: bar.volumeMuted ? Colors.fgMuted : Md3.md3.primary; Layout.alignment: Qt.AlignVCenter; renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting }
                    Text { text: bar.volumePercent + "%"; font.family: Appearance.font.ui; font.pixelSize: 14; font.weight: Font.Bold; color: Colors.fgDim; Layout.alignment: Qt.AlignVCenter; renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: volumePopup.toggle()
                        onWheel: wheel => { var s = Pipewire.defaultAudioSink; if (s?.audio) s.audio.volume = Math.max(0, Math.min(1.5, s.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))) }
                    }
                }

                Sep {}

                // Network (click = nm-connection-editor)
                RowLayout {
                    spacing: 4; Layout.alignment: Qt.AlignVCenter
                    Text { text: bar.networkType === "wifi" ? "󰤢" : (bar.networkConnected ? "󰈀" : "󰤠"); font.family: Appearance.font.mono; font.pixelSize: 17; color: bar.networkConnected ? Md3.md3.primary : Colors.fgMuted; Layout.alignment: Qt.AlignVCenter; renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting }
                    Text { visible: bar.networkType === "wifi" && bar.networkName.length > 0; text: bar.networkName; font.family: Appearance.font.ui; font.pixelSize: 14; font.weight: Font.Bold; color: Colors.fgDim; elide: Text.ElideRight; Layout.maximumWidth: 100; Layout.alignment: Qt.AlignVCenter; renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.exec(["nm-connection-editor"]) }
                }

                Sep {}

                // Battery (click = popup with power profiles)
                RowLayout {
                    id: batteryArea
                    spacing: 4; Layout.alignment: Qt.AlignVCenter
                    Canvas {
                        Layout.preferredWidth: 20; Layout.preferredHeight: 20; Layout.alignment: Qt.AlignVCenter
                        property real pct: bar.batteryPercent / 100.0
                        onPctChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                            var cx = width/2, cy = height/2, r = 8
                            ctx.lineWidth = 2.5; ctx.lineCap = "round"
                            ctx.strokeStyle = Qt.rgba(1,1,1,0.08); ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2*Math.PI); ctx.stroke()
                            ctx.strokeStyle = bar.batteryCharging ? Md3.md3.primary : (bar.batteryPercent > 20 ? Md3.md3.primary : Md3.md3.error)
                            ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + pct*2*Math.PI); ctx.stroke()
                        }
                    }
                    Text { text: bar.batteryPercent + "%"; font.family: Appearance.font.ui; font.pixelSize: 14; font.weight: Font.Bold; color: Colors.fgDim; Layout.alignment: Qt.AlignVCenter; renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: batteryPopup.toggle() }
                }

                Sep {}

                // Bell
                Text {
                    text: "󰂚"; font.family: Appearance.font.mono; font.pixelSize: 17
                    color: Colors.fg; Layout.alignment: Qt.AlignVCenter
                    renderType: Text.NativeRendering; font.hintingPreference: Font.PreferFullHinting
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.exec(["swaync-client", "-t", "-sw"]) }
                }
            }
        }
    }

    // Volume popup — positioned under volume area in right pill
    PopupBase {
        id: volumePopup; barWindow: bar; anchorItem: volumeArea
        popupWidth: 220; popupHeight: 160
        bgColor: Md3.md3.surface_container_high; borderColor: Md3.md3.outline_variant
        VolumePopup { anchors.fill: parent; accent: Md3.md3.primary; fg: Colors.fg; fgDim: Colors.fgDim; fgMuted: Colors.fgMuted; bgHighlight: Md3.md3.surface_container_highest }
    }

    // Battery popup — power profiles
    PopupBase {
        id: batteryPopup; barWindow: bar; anchorItem: batteryArea
        popupWidth: 230; popupHeight: 260
        bgColor: Md3.md3.surface_container_high; borderColor: Md3.md3.outline_variant
        BatteryPopup { anchors.fill: parent; accent: Md3.md3.primary; fg: Colors.fg; fgDim: Colors.fgDim; fgMuted: Colors.fgMuted; bgHighlight: Md3.md3.surface_container_highest; percent: bar.batteryPercent; charging: bar.batteryCharging }
    }
}
