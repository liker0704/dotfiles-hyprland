import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import ".."

Scope {
    id: root

    property bool showVolume: false
    property bool showBrightness: false
    property real volumeValue: 0
    property bool volumeMuted: false
    property real brightnessValue: 0
    property real brightnessMax: 100

    // --- Volume tracking ---
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    property real _lastVol: -1
    property bool _lastMuted: false

    Timer {
        interval: 200; running: true; repeat: true
        onTriggered: {
            var sink = Pipewire.defaultAudioSink
            if (!sink || !sink.audio) return
            var v = sink.audio.volume
            var m = sink.audio.muted
            if (Math.abs(v - root._lastVol) > 0.001 || m !== root._lastMuted) {
                if (root._lastVol >= 0) {
                    root.volumeValue = v
                    root.volumeMuted = m
                    root.showVolume = true
                    volumeHide.restart()
                }
                root._lastVol = v
                root._lastMuted = m
            }
        }
    }

    // --- Brightness tracking ---
    Process {
        id: findBacklight
        command: ["bash", "-c", "ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim()
                if (p) {
                    brightnessFile.path = p
                    var maxPath = p.replace("/brightness", "/max_brightness")
                    maxBrightnessFile.path = maxPath
                }
            }
        }
    }

    FileView {
        id: maxBrightnessFile
        onTextChanged: {
            var v = parseInt(text())
            if (v > 0) root.brightnessMax = v
        }
    }

    FileView {
        id: brightnessFile
        watchChanges: true
        property real _lastBri: -1
        onTextChanged: {
            var v = parseInt(text())
            if (!isNaN(v)) {
                var normalized = v / root.brightnessMax
                if (Math.abs(normalized - _lastBri) > 0.001) {
                    if (_lastBri >= 0) {
                        root.brightnessValue = normalized
                        root.showBrightness = true
                        brightnessHide.restart()
                    }
                    _lastBri = normalized
                }
            }
        }
    }

    // --- Auto-hide ---
    Timer { id: volumeHide; interval: 1500; onTriggered: root.showVolume = false }
    Timer { id: brightnessHide; interval: 1500; onTriggered: root.showBrightness = false }

    // --- OSD Window ---
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.showVolume || root.showBrightness
            focusable: false
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors { bottom: true }
            margins.bottom: 80
            implicitWidth: 240
            implicitHeight: 60

            // Center horizontally
            anchors.left: true
            anchors.right: true

            Colors { id: colors }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: 220; height: 50
                radius: 25
                color: Qt.rgba(colors.bg.r, colors.bg.g, colors.bg.b, 0.95)
                border.width: 1
                border.color: Qt.rgba(colors.fg.r, colors.fg.g, colors.fg.b, 0.06)

                opacity: (root.showVolume || root.showBrightness) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    // Icon
                    Text {
                        text: {
                            if (root.showVolume) {
                                if (root.volumeMuted) return "󰝟"
                                if (root.volumeValue > 0.5) return "󰕾"
                                if (root.volumeValue > 0) return "󰖀"
                                return "󰕿"
                            }
                            return "󰃠"
                        }
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                        color: root.volumeMuted ? colors.fgMuted : colors.accent
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Progress bar
                    Rectangle {
                        Layout.preferredWidth: 120; Layout.preferredHeight: 6
                        radius: 3; color: colors.bgHighlight
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            width: parent.width * (root.showVolume ? root.volumeValue : root.brightnessValue)
                            height: parent.height; radius: 3
                            color: root.volumeMuted ? colors.fgMuted : colors.accent
                            Behavior on width { NumberAnimation { duration: 80 } }
                        }
                    }

                    // Percentage
                    Text {
                        text: Math.round((root.showVolume ? root.volumeValue : root.brightnessValue) * 100) + "%"
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.weight: Font.Bold
                        color: colors.fgDim
                        Layout.preferredWidth: 35
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
