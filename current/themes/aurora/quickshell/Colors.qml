import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.config/theme/palette.conf"
        watchChanges: true
        onTextChanged: root.reload()
    }

    property var _map: ({})

    function reload() {
        var map = {}
        var lines = (paletteFile.text() || "").split('\n')
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line && line[0] !== '#' && line.indexOf('=') > 0) {
                var eq = line.indexOf('=')
                var key = line.substring(0, eq).trim()
                var val = line.substring(eq + 1).trim()
                if (val.length > 0) map[key] = '#' + val
            }
        }
        _map = map
    }

    function c(key, fallbackKey) {
        if (_map[key]) return _map[key]
        if (fallbackKey && _map[fallbackKey]) return _map[fallbackKey]
        return "#ff00ff"
    }

    // === BASE ===
    readonly property color bg: c("bg")
    readonly property color bgLight: c("bg_light")
    readonly property color bgHighlight: c("bg_highlight")
    readonly property color fg: c("fg")
    readonly property color fgDim: c("fg_dim")
    readonly property color fgMuted: c("fg_muted")
    readonly property color border: c("border")

    // === DERIVED (with alpha) ===
    readonly property color bgPill: Qt.rgba(bg.r, bg.g, bg.b, 0.97)
    readonly property color bgHover: Qt.rgba(bgLight.r, bgLight.g, bgLight.b, 0.97)

    // === ACCENT (semantic — fallback to terminal colors for monochrome) ===
    readonly property color accent: c("accent", "blue")
    readonly property color accentSecondary: c("accent_secondary", "magenta")
    readonly property color accentTertiary: c("accent_tertiary", "green")

    // === STATUS ===
    readonly property color error: c("error", "red")
    readonly property color warning: c("warning", "yellow")
    readonly property color success: c("success", "green")
    readonly property color info: c("info", "cyan")

    // === TERMINAL 16 ===
    readonly property color black: c("black")
    readonly property color brightBlack: c("bright_black")
    readonly property color red: c("red")
    readonly property color brightRed: c("bright_red")
    readonly property color green: c("green")
    readonly property color brightGreen: c("bright_green")
    readonly property color yellow: c("yellow")
    readonly property color brightYellow: c("bright_yellow")
    readonly property color blue: c("blue")
    readonly property color brightBlue: c("bright_blue")
    readonly property color magenta: c("magenta")
    readonly property color brightMagenta: c("bright_magenta")
    readonly property color cyan: c("cyan")
    readonly property color brightCyan: c("bright_cyan")
    readonly property color white: c("white")
    readonly property color brightWhite: c("bright_white")

    // === CURSOR / URL ===
    readonly property color cursorColor: c("cursor", "fg")
    readonly property color urlColor: c("url", "cyan")

    Component.onCompleted: reload()
}
