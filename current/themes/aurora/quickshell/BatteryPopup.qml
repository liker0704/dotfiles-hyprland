import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: bat

    property color accent: "#7aa8ff"
    property color fg: "#e6e6f0"
    property color fgDim: "#a5a9c2"
    property color fgMuted: "#6f7590"
    property color bgHighlight: "#3f4053"

    property int percent: 0
    property bool charging: false
    property string currentProfile: "balanced"

    // Read power profile
    Process {
        id: profileProc; running: true
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser { onRead: data => { bat.currentProfile = data.trim() } }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: { profileProc.running = false; profileProc.running = true } }

    Process {
        id: setProfileProc
        property string target: ""
        command: ["powerprofilesctl", "set", target]
        onRunningChanged: {
            if (!running && target !== "") {
                profileProc.running = false
                profileProc.running = true
            }
        }
    }

    function setProfile(name) {
        setProfileProc.target = name
        setProfileProc.running = true
        currentProfile = name
    }

    readonly property var profiles: [
        { name: "performance", icon: "󰓅", label: "Performance" },
        { name: "balanced",    icon: "󰾅", label: "Balanced" },
        { name: "power-saver", icon: "󰌪", label: "Power Saver" }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Battery info
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Big ring
            Canvas {
                Layout.preferredWidth: 52; Layout.preferredHeight: 52
                property real pct: bat.percent / 100.0
                onPctChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                    var cx = width/2, cy = height/2, r = 22
                    ctx.lineWidth = 5; ctx.lineCap = "round"
                    ctx.strokeStyle = Qt.rgba(1,1,1,0.08)
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2*Math.PI); ctx.stroke()
                    ctx.strokeStyle = bat.percent > 20 ? bat.accent.toString() : "#ff6b7a"
                    ctx.beginPath(); ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + pct*2*Math.PI); ctx.stroke()
                }
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: bat.percent + "%"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24; font.weight: Font.Bold
                    color: bat.fg
                }
                Text {
                    text: bat.charging ? "󱐋 Charging" : "󰁹 On Battery"
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11
                    color: bat.fgDim
                }
            }
        }

        // Separator
        Rectangle { Layout.fillWidth: true; height: 1; color: bat.bgHighlight }

        // Power profile label
        Text {
            text: "Power Mode"
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.Bold
            color: bat.fgMuted
        }

        // Profile buttons
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: bat.profiles

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    radius: 10
                    color: bat.currentProfile === modelData.name ? Qt.rgba(bat.accent.r, bat.accent.g, bat.accent.b, 0.18) : bat.bgHighlight

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: modelData.icon
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                            color: bat.currentProfile === modelData.name ? bat.accent : bat.fgDim
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: modelData.label
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.weight: Font.Bold
                            color: bat.currentProfile === modelData.name ? bat.accent : bat.fg
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: bat.currentProfile === modelData.name
                            text: "✓"
                            font.pixelSize: 12; color: bat.accent
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: bat.setProfile(modelData.name)
                    }
                }
            }
        }
    }
}
