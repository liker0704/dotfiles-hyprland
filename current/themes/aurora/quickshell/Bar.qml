import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 36
    margins.top: 3
    margins.left: 4
    margins.right: 4
    color: "transparent"

    // --- Colors (reactive — auto-updates on theme sync) ---
    Colors { id: colors }

    // --- Hyprland monitor ---
    property HyprlandMonitor monitor: Hyprland.monitorFor(bar.screen)

    // --- Battery (FileView — reactive, no polling) ---
    FileView { id: batCapacity; path: "/sys/class/power_supply/BAT0/capacity"; watchChanges: true }
    FileView { id: batStatus; path: "/sys/class/power_supply/BAT0/status"; watchChanges: true }
    property int batteryPercent: parseInt(batCapacity.text()) || 0
    property bool batteryCharging: (batStatus.text().trim() === "Charging")

    // --- Volume (native Pipewire) ---
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    property real volumeRaw: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    property int volumePercent: Math.round(volumeRaw * 100)
    property bool volumeMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    // --- Network (polled) ---
    property string networkName: ""
    property bool networkConnected: false
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: netProc.running = true
    }
    Process {
        id: netProc
        running: true
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE,CONNECTION d | grep -E 'wifi:connected|ethernet:connected' | head -1 | cut -d: -f3"]
        stdout: SplitParser {
            onRead: data => {
                bar.networkConnected = data.trim().length > 0
                bar.networkName = data.trim()
            }
        }
    }

    // --- Clock ---
    property string timeStr: Qt.formatDateTime(new Date(), "HH:mm  •  ddd, d MMM")
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: bar.timeStr = Qt.formatDateTime(new Date(), "HH:mm  •  ddd, d MMM")
    }

    // ==================== LAYOUT ====================
    RowLayout {
        anchors.fill: parent
        spacing: 6

        // --- LEFT: Workspaces ---
        Rectangle {
            color: colors.bgPill
            radius: 999
            Layout.preferredHeight: parent.height - 2
            Layout.preferredWidth: wsRow.implicitWidth + 14
            Layout.alignment: Qt.AlignVCenter

            Row {
                id: wsRow
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: {
                        var ws = Hyprland.workspaces.values
                        var filtered = []
                        for (var i = 0; i < ws.length; i++) {
                            if (ws[i].id > 0) filtered.push(ws[i])
                        }
                        filtered.sort(function(a, b) { return a.id - b.id })
                        return filtered
                    }

                    Rectangle {
                        required property var modelData
                        property bool isActive: modelData.id === bar.monitor.activeWorkspace?.id

                        width: 26; height: 26; radius: 8
                        color: isActive ? colors.accent : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.id.toString()
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: parent.isActive ? colors.bgPill : colors.fgMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("workspace " + modelData.id)
                        }
                    }
                }
            }
        }

        // --- SPACER ---
        Item { Layout.fillWidth: true }

        // --- CENTER: Clock ---
        Rectangle {
            color: colors.bgPill
            radius: 999
            Layout.preferredHeight: parent.height - 2
            Layout.preferredWidth: clockText.implicitWidth + 28
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: clockText
                anchors.centerIn: parent
                text: bar.timeStr
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: colors.fg
            }
        }

        // --- SPACER ---
        Item { Layout.fillWidth: true }

        // --- RIGHT: Tray ---
        Rectangle {
            color: colors.bgPill
            radius: 999
            Layout.preferredHeight: parent.height - 2
            Layout.preferredWidth: trayRow.implicitWidth + 16
            Layout.alignment: Qt.AlignVCenter
            visible: trayRow.children.length > 0

            Row {
                id: trayRow
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: SystemTray.items
                    Image {
                        required property var modelData
                        source: modelData.icon
                        width: 20; height: 20
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        sourceSize.width: 20
                        sourceSize.height: 20
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton)
                                    modelData.activate()
                                else if (mouse.button === Qt.RightButton && modelData.hasMenu)
                                    modelData.display(bar, mouse.x, mouse.y)
                            }
                        }
                    }
                }
            }
        }

        // --- Network ---
        Rectangle {
            color: colors.bgPill
            radius: 999
            Layout.preferredHeight: parent.height - 2
            Layout.preferredWidth: 38
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: bar.networkConnected ? "󰤢" : "󰤠"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: bar.networkConnected ? colors.success : colors.fgMuted
            }
        }

        // --- Volume ---
        Rectangle {
            color: colors.bgPill
            radius: 999
            Layout.preferredHeight: parent.height - 2
            Layout.preferredWidth: volRow.implicitWidth + 20
            Layout.alignment: Qt.AlignVCenter

            Row {
                id: volRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: bar.volumeMuted ? "󰝟" : (bar.volumePercent > 50 ? "󰕾" : "󰖀")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: bar.volumeMuted ? colors.fgMuted : colors.accentSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: bar.volumePercent + "%"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: colors.fgDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var sink = Pipewire.defaultAudioSink
                    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
                }
                onWheel: wheel => {
                    var sink = Pipewire.defaultAudioSink
                    if (sink && sink.audio) {
                        sink.audio.volume = Math.max(0, Math.min(1.5,
                            sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
                    }
                }
            }
        }

        // --- Battery with ring ---
        Rectangle {
            color: colors.bgPill
            radius: 999
            Layout.preferredHeight: parent.height - 2
            Layout.preferredWidth: batRow.implicitWidth + 20
            Layout.alignment: Qt.AlignVCenter

            Row {
                id: batRow
                anchors.centerIn: parent
                spacing: 5

                Canvas {
                    id: batRing
                    width: 20; height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    property real pct: bar.batteryPercent / 100.0
                    onPctChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var cx = width / 2, cy = height / 2, r = 8

                        ctx.lineWidth = 3
                        ctx.lineCap = "round"
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                        ctx.stroke()

                        ctx.strokeStyle = bar.batteryCharging ? colors.info
                            : (bar.batteryPercent > 20 ? colors.success : colors.error)
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + pct * 2 * Math.PI)
                        ctx.stroke()
                    }
                }

                Text {
                    text: bar.batteryPercent + "%"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: bar.batteryCharging ? colors.info : colors.fgDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // --- Power ---
        Rectangle {
            color: Qt.rgba(1, 0.42, 0.48, 0.12)
            radius: 999
            Layout.preferredHeight: parent.height - 2
            Layout.preferredWidth: 34
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "⏻"
                font.pixelSize: 13
                color: colors.error
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.exec(["bash", "-c", "~/.config/hypr/scripts/Wlogout.sh"])
            }
        }
    }
}
