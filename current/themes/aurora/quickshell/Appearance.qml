pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Rounding
    readonly property QtObject rounding: QtObject {
        readonly property real small: 8
        readonly property real normal: 14
        readonly property real large: 20
        readonly property real pill: 999
    }

    // Spacing
    readonly property QtObject spacing: QtObject {
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 24
    }

    // Font sizes (pointSize for DPI independence)
    readonly property QtObject font: QtObject {
        readonly property string family: "JetBrainsMono Nerd Font"
        readonly property int caption: 9
        readonly property int label: 10
        readonly property int body: 11
        readonly property int bodyLarge: 12
        readonly property int title: 14
        readonly property int titleLarge: 16
        readonly property int headline: 22
        readonly property int display: 36
        readonly property int displayLarge: 64
    }

    // Shadows
    readonly property QtObject shadow: QtObject {
        readonly property real small: 8
        readonly property real medium: 16
        readonly property real large: 24
        readonly property real opacity: 0.3
    }

    // Animation durations
    readonly property QtObject anim: QtObject {
        readonly property int fast: 120
        readonly property int normal: 200
        readonly property int slow: 350
        readonly property real spring: 3.5     // spring constant
        readonly property real damping: 0.7
    }

    // Bar
    readonly property QtObject bar: QtObject {
        readonly property int height: 36
        readonly property int margin: 4
        readonly property int pillPadding: 6
    }

    // Popups
    readonly property QtObject popup: QtObject {
        readonly property int width: 280
        readonly property int padding: 14
        readonly property real bgAlpha: 0.97
    }

    // Notifications
    readonly property QtObject notif: QtObject {
        readonly property int width: 370
        readonly property int maxVisible: 5
        readonly property real bgAlpha: 0.96
    }
}
