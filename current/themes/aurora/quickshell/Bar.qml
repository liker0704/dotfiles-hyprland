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
    margins.top: 4
    margins.left: 6
    margins.right: 6
    color: "transparent"
    Colors { id: colors }

    property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)
    property real pillHeight: bar.height - 10

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
    Timer { interval: 5000; running: true; repeat: true; onTriggered: netProc.running = true }
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
    Timer { interval: 1000; running: true; repeat: true; onTriggered: bar.timeStr = Qt.formatDateTime(new Date(), "h:mm AP") }

    component Sep: Rectangle {
        width: 1; Layout.preferredHeight: 14; radius: 1
        color: colors.fgMuted; opacity: 0.25; Layout.alignment: Qt.AlignVCenter
    }

    // ==================== CLOCK (absolute center) ====================
    Rectangle {
        id: clockPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: clockText.implicitWidth + 26; height: pillHeight; radius: height / 2
        color: colors.bgPill
        Text {
            id: clockText; anchors.centerIn: parent; text: bar.timeStr
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.weight: Font.DemiBold; color: colors.fg
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: calendarPopup.toggle() }
    }

    // Calendar popup — centered under clock (clock is horizontalCenter of bar)
    PopupBase {
        id: calendarPopup; barWindow: bar; anchorItem: clockPill
        popupWidth: 280; popupHeight: 290
        bgColor: colors.bg; borderColor: Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.15)
        CalendarPopup { anchors.fill: parent; accent: colors.accent; fg: colors.fg; fgDim: colors.fgDim; fgMuted: colors.fgMuted; bgHighlight: colors.bgHighlight }
    }

    // ==================== LEFT SECTION ====================
    RowLayout {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Workspaces
        Rectangle {
            color: colors.bgPill; radius: height / 2
            height: pillHeight; implicitWidth: wsRow.implicitWidth + 16

            RowLayout {
                id: wsRow; anchors.centerIn: parent; spacing: 3
                Repeater {
                    model: {
                        var ws = Hyprland.workspaces.values; var f = []
                        for (var i = 0; i < ws.length; i++) { if (ws[i].id > 0) f.push(ws[i]) }
                        f.sort(function(a, b) { return a.id - b.id }); return f
                    }
                    Rectangle {
                        required property var modelData
                        property bool isActive: modelData.id === bar.monitor.activeWorkspace?.id
                        Layout.preferredWidth: 26; Layout.preferredHeight: 26; radius: 8
                        color: isActive ? colors.accent : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent; text: modelData.id.toString()
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold
                            color: parent.isActive ? colors.bg : colors.fgMuted
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
                Layout.preferredWidth: visible ? 18 : 0; Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.fill: parent
                    source: modelData.icon
                    fillMode: Image.PreserveAspectFit; smooth: true
                    sourceSize.width: 18; sourceSize.height: 18
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(event) {
                        if (event.button === Qt.RightButton) {
                            if (modelData.hasMenu) {
                                // anchor.item places menu below the icon
                                modelData.display(bar, parent.x, bar.implicitHeight)
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
            color: colors.bgPill; radius: height / 2
            height: pillHeight; implicitWidth: statusRow.implicitWidth + 28

            RowLayout {
                id: statusRow; anchors.centerIn: parent; spacing: 10

                // Volume (click = popup, scroll = volume)
                RowLayout {
                    id: volumeArea
                    spacing: 4; Layout.alignment: Qt.AlignVCenter
                    Text { text: bar.volumeMuted ? "󰝟" : "󰕾"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: bar.volumeMuted ? colors.fgMuted : colors.accent; Layout.alignment: Qt.AlignVCenter }
                    Text { text: bar.volumePercent + "%"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: colors.fgDim; Layout.alignment: Qt.AlignVCenter }
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
                    Text { text: bar.networkType === "wifi" ? "󰤢" : (bar.networkConnected ? "󰈀" : "󰤠"); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: bar.networkConnected ? colors.accent : colors.fgMuted; Layout.alignment: Qt.AlignVCenter }
                    Text { visible: bar.networkType === "wifi" && bar.networkName.length > 0; text: bar.networkName; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: colors.fgDim; elide: Text.ElideRight; Layout.maximumWidth: 80; Layout.alignment: Qt.AlignVCenter }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.exec(["nm-connection-editor"]) }
                }

                Sep {}

                // Battery (click = popup with power profiles)
                RowLayout {
                    id: batteryArea
                    spacing: 4; Layout.alignment: Qt.AlignVCenter
                    Canvas {
                        Layout.preferredWidth: 18; Layout.preferredHeight: 18; Layout.alignment: Qt.AlignVCenter
                        property real pct: bar.batteryPercent / 100.0
                        onPctChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                            var cx = width/2, cy = height/2, r = 7
                            ctx.lineWidth = 2.5; ctx.lineCap = "round"
                            ctx.strokeStyle = Qt.rgba(1,1,1,0.08); ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2*Math.PI); ctx.stroke()
                            ctx.strokeStyle = bar.batteryCharging ? colors.accent.toString() : (bar.batteryPercent > 20 ? colors.accent.toString() : colors.error.toString())
                            ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + pct*2*Math.PI); ctx.stroke()
                        }
                    }
                    Text { text: bar.batteryPercent + "%"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold; color: colors.fgDim; Layout.alignment: Qt.AlignVCenter }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: batteryPopup.toggle() }
                }

                Sep {}

                // Bell
                Text {
                    text: "󰂚"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                    color: colors.fg; Layout.alignment: Qt.AlignVCenter
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.exec(["swaync-client", "-t", "-sw"]) }
                }
            }
        }
    }

    // Volume popup — positioned under volume area in right pill
    PopupBase {
        id: volumePopup; barWindow: bar; anchorItem: volumeArea
        popupWidth: 220; popupHeight: 160
        bgColor: colors.bg; borderColor: Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.15)
        VolumePopup { anchors.fill: parent; accent: colors.accent; fg: colors.fg; fgDim: colors.fgDim; fgMuted: colors.fgMuted; bgHighlight: colors.bgHighlight }
    }

    // Battery popup — power profiles
    PopupBase {
        id: batteryPopup; barWindow: bar; anchorItem: batteryArea
        popupWidth: 230; popupHeight: 260
        bgColor: colors.bg; borderColor: Qt.rgba(colors.accent.r, colors.accent.g, colors.accent.b, 0.15)
        BatteryPopup { anchors.fill: parent; accent: colors.accent; fg: colors.fg; fgDim: colors.fgDim; fgMuted: colors.fgMuted; bgHighlight: colors.bgHighlight; percent: bar.batteryPercent; charging: bar.batteryCharging }
    }
}
