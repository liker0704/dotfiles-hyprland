import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire

Item {
    id: vol

    property color accent: "#7aa8ff"
    property color fg: "#e6e6f0"
    property color fgDim: "#a5a9c2"
    property color fgMuted: "#6f7590"
    property color bgHighlight: "#3f4053"

    property real volume: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Volume percentage
        Text {
            text: Math.round(vol.volume * 100) + "%"
            color: vol.muted ? vol.fgMuted : vol.fg
            font.family: Appearance.font.ui
            font.pixelSize: 36; font.weight: Font.Bold
            Layout.alignment: Qt.AlignHCenter
        }

        // Slider
        Slider {
            id: volSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            from: 0; to: 1; stepSize: 0.01
            value: vol.volume
            onMoved: {
                var sink = Pipewire.defaultAudioSink
                if (sink && sink.audio) sink.audio.volume = value
            }

            background: Rectangle {
                x: volSlider.leftPadding; y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                width: volSlider.availableWidth; height: 6; radius: 3
                color: vol.bgHighlight

                Rectangle {
                    width: volSlider.visualPosition * parent.width; height: parent.height; radius: 3
                    color: vol.muted ? vol.fgMuted : vol.accent
                }
            }

            handle: Rectangle {
                x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                width: 16; height: 16; radius: 8
                color: vol.muted ? vol.fgMuted : vol.accent
            }
        }

        // Mute button
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32
            radius: 8
            color: vol.muted ? vol.accent : vol.bgHighlight

            Text {
                anchors.centerIn: parent
                text: vol.muted ? "󰖁  Unmute" : "󰕾  Mute"
                color: vol.muted ? "#000000" : vol.fgDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12; font.weight: Font.Bold
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var sink = Pipewire.defaultAudioSink
                    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
                }
            }
        }
    }
}
