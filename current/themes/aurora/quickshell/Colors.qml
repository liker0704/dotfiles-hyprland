import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false

    property string _palettePath: Quickshell.env("HOME") + "/.config/theme/palette.conf"
    property string _paletteDir: Quickshell.env("HOME") + "/.config/theme"

    // --- Read palette file ---
    Process {
        id: readProc
        command: ["cat", root._palettePath]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root.parsePalette(data)
        }
    }

    // --- Watch directory for instant file replacement detection ---
    Process {
        id: watcher
        running: true
        command: [
            "inotifywait", "-m", "-q",
            "-e", "close_write,moved_to",
            "--format", "%f",
            root._paletteDir
        ]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "palette.conf") {
                    readProc.running = false
                    readProc.running = true
                }
            }
        }
        onRunningChanged: {
            if (!running) running = true
        }
    }

    Component.onCompleted: { readProc.running = true }

    // --- Parse ---
    property var _map: ({})

    function parsePalette(content) {
        var map = {}
        var lines = content.split('\n')
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
        applyColors()
    }

    function c(key, fallbackKey) {
        if (_map[key]) return _map[key]
        if (fallbackKey && _map[fallbackKey]) return _map[fallbackKey]
        return "#ff00ff"
    }

    function applyColors() {
        bg = c("bg"); bgLight = c("bg_light"); bgHighlight = c("bg_highlight")
        fg = c("fg"); fgDim = c("fg_dim"); fgMuted = c("fg_muted"); border = c("border")
        bgPill = Qt.rgba(bg.r, bg.g, bg.b, 0.97)
        bgHover = Qt.rgba(bgLight.r, bgLight.g, bgLight.b, 0.97)
        accent = c("accent", "blue"); accentSecondary = c("accent_secondary", "accent")
        accentTertiary = c("accent_tertiary", "green")
        error = c("error", "red"); warning = c("warning", "yellow")
        success = c("success", "green"); info = c("info", "cyan")
        black = c("black"); brightBlack = c("bright_black")
        red = c("red"); brightRed = c("bright_red")
        green = c("green"); brightGreen = c("bright_green")
        yellow = c("yellow"); brightYellow = c("bright_yellow")
        blue = c("blue"); brightBlue = c("bright_blue")
        magenta = c("magenta"); brightMagenta = c("bright_magenta")
        cyan = c("cyan"); brightCyan = c("bright_cyan")
        white = c("white"); brightWhite = c("bright_white")
        cursorColor = c("cursor", "fg"); urlColor = c("url", "cyan")
    }

    // === BASE ===
    property color bg: "#1e1e2e"
    property color bgLight: "#2a2a3b"
    property color bgHighlight: "#3f4053"
    property color fg: "#cdd6f4"
    property color fgDim: "#9399b2"
    property color fgMuted: "#6c7087"
    property color border: "#4f5165"
    property color bgPill: Qt.rgba(bg.r, bg.g, bg.b, 0.97)
    property color bgHover: Qt.rgba(bgLight.r, bgLight.g, bgLight.b, 0.97)

    // === ACCENT ===
    property color accent: "#7aa8ff"
    property color accentSecondary: "#c99bff"
    property color accentTertiary: "#7be0a7"

    // === STATUS ===
    property color error: "#ff6b7a"
    property color warning: "#ffd580"
    property color success: "#7be0a7"
    property color info: "#6ee7e7"

    // === TERMINAL 16 ===
    property color black: "#232631"
    property color brightBlack: "#3a3f52"
    property color red: "#ff6b7a"
    property color brightRed: "#ff8594"
    property color green: "#7be0a7"
    property color brightGreen: "#95ebb9"
    property color yellow: "#ffd580"
    property color brightYellow: "#ffe199"
    property color blue: "#7aa8ff"
    property color brightBlue: "#9abdff"
    property color magenta: "#c99bff"
    property color brightMagenta: "#d6b3ff"
    property color cyan: "#6ee7e7"
    property color brightCyan: "#8ceded"
    property color white: "#cdd1e4"
    property color brightWhite: "#e6e6f0"

    // === CURSOR / URL ===
    property color cursorColor: "#7aa8ff"
    property color urlColor: "#6ee7e7"
}
