import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ".."

Scope {
    id: root

    property bool showVolume: false
    property bool showBrightness: false
    property real volumeValue: 0
    property bool volumeMuted: false
    property real brightnessValue: 0
    property real brightnessMax: 100

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    property real _lastVol: -1
    property bool _lastMuted: false

    function _onVolumeEvent() {
        var sink = Pipewire.defaultAudioSink
        if (!sink || !sink.audio) return
        var v = sink.audio.volume; var m = sink.audio.muted
        if (Math.abs(v - root._lastVol) < 0.001 && m === root._lastMuted) return
        if (root._lastVol >= 0) {
            root.volumeValue = v; root.volumeMuted = m
            root.showVolume = true; volumeHide.restart()
        }
        root._lastVol = v; root._lastMuted = m
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null
        function onVolumeChanged() { root._onVolumeEvent() }
        function onMutedChanged() { root._onVolumeEvent() }
    }

    Process {
        id: findBacklight; command: ["bash", "-c", "ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1"]; running: true
        stdout: SplitParser { onRead: data => { var p = data.trim(); if (p) { brightnessFile.path = p; maxBrightnessFile.path = p.replace("/brightness", "/max_brightness") } } }
    }
    FileView { id: maxBrightnessFile; onTextChanged: { var v = parseInt(text()); if (v > 0) root.brightnessMax = v } }
    FileView {
        id: brightnessFile; watchChanges: true; property real _last: -1
        onTextChanged: { var v = parseInt(text()); if (!isNaN(v)) { var n = v / root.brightnessMax; if (Math.abs(n - _last) > 0.001) { if (_last >= 0) { root.brightnessValue = n; root.showBrightness = true; brightnessHide.restart() }; _last = n } } }
    }

    Timer { id: volumeHide; interval: 1500; onTriggered: root.showVolume = false }
    Timer { id: brightnessHide; interval: 1500; onTriggered: root.showBrightness = false }

    property bool showOsd: showVolume || showBrightness

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData; screen: modelData
            visible: root.showOsd; focusable: false; color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay; WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            // Anchor only to bottom — compositor sizes layer to implicitWidth
            // (260) and centers it. With left+right anchored the layer
            // stretched full screen-width for no reason (260px content).
            anchors { bottom: true }
            margins.bottom: 80; implicitWidth: 260; implicitHeight: 70


            Item {
                anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter
                width: 230; height: 54

                RectangularShadow {
                    anchors.fill: osdBg; radius: osdBg.radius
                    blur: 12; spread: 1; color: Qt.rgba(0, 0, 0, 0.25); offset: Qt.vector2d(0, 2)
                }

                Rectangle {
                    id: osdBg; anchors.fill: parent; radius: 27
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
                    border.width: 1; border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                    antialiasing: true

                    opacity: root.showOsd ? 1 : 0
                    scale: root.showOsd ? 1 : 0.9
                    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

                    RowLayout {
                        anchors.centerIn: parent; spacing: Appearance.spacing.md

                        Text {
                            text: root.showVolume ? (root.volumeMuted ? "󰝟" : root.volumeValue > 0.5 ? "󰕾" : "󰖀") : "󰃠"
                            font.family: Appearance.font.family; font.pointSize: Appearance.font.titleLarge
                            color: root.volumeMuted ? Colors.fgMuted : Colors.accent
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Rectangle {
                            Layout.preferredWidth: 120; Layout.preferredHeight: 6; radius: 3
                            color: Colors.bgHighlight; Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                width: parent.width * Math.min(1, root.showVolume ? root.volumeValue : root.brightnessValue)
                                height: parent.height; radius: 3
                                color: root.volumeMuted ? Colors.fgMuted : Colors.accent
                                Behavior on width { NumberAnimation { duration: 80 } }
                            }
                        }

                        Text {
                            text: Math.round((root.showVolume ? root.volumeValue : root.brightnessValue) * 100) + "%"
                            font.family: Appearance.font.ui; font.pointSize: Appearance.font.body; font.bold: true
                            color: Colors.fgDim; Layout.preferredWidth: 35; Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
