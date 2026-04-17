import QtQuick
import ".."

// Thin wrapper around Colors singleton — used to be a duplicate palette
// watcher (second inotifywait on ~/.config/theme). Now just exposes bindings
// the notification card expects (bg is semi-transparent, etc.)

QtObject {
    id: root

    property color bg: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
    property color bgCard: Colors.bg
    property color bgHighlight: Colors.bgHighlight
    property color fg: Colors.fg
    property color fgDim: Colors.fgDim
    property color fgMuted: Colors.fgMuted
    property color accent: Colors.accent
    property color error: Colors.error
    property color border: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
    property color borderCritical: Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.4)
}
