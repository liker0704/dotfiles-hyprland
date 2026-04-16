import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    visible: false

    property string _palettePath: Quickshell.env("HOME") + "/.config/theme/palette.conf"
    property string _paletteDir: Quickshell.env("HOME") + "/.config/theme"

    FileView {
        id: paletteFile
        path: root._palettePath
        onLoadedChanged: if (loaded) root.reload()
    }

    Process {
        id: watcher; running: true
        command: ["inotifywait", "-m", "-q", "-e", "close_write,moved_to", "--format", "%f", root._paletteDir]
        stdout: SplitParser { onRead: data => { if (data.trim() === "palette.conf") root.reload() } }
        onRunningChanged: { if (!running) running = true }
    }

    function reload() {
        var content = paletteFile.text()
        if (!content || content.length === 0) return
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
        // Set all properties directly from map
        var cc = function(k, fb) { return map[k] || (fb ? map[fb] : null) || "#ff00ff" }
        var h = function(hex, a) {
            var s = hex.replace("#","")
            return Qt.rgba(parseInt(s.substring(0,2),16)/255, parseInt(s.substring(2,4),16)/255, parseInt(s.substring(4,6),16)/255, a)
        }
        root.bg = cc("bg"); root.bgLight = cc("bg_light"); root.bgHighlight = cc("bg_highlight")
        root.fg = cc("fg"); root.fgDim = cc("fg_dim"); root.fgMuted = cc("fg_muted"); root.border = cc("border")
        root.bgPill = h(cc("bg"), 0.97); root.bgHover = h(cc("bg_light"), 0.97)
        root.accent = cc("accent", "green"); root.accentSecondary = cc("accent_secondary", "blue")
        root.error = cc("error", "red"); root.warning = cc("warning", "yellow")
        root.success = cc("success", "green"); root.info = cc("info", "cyan")
    }

    property var _map: ({})
    property color bg: "#1a1b26"
    property color bgLight: "#24283b"
    property color bgHighlight: "#3b4261"
    property color fg: "#c0caf5"
    property color fgDim: "#9aa5ce"
    property color fgMuted: "#565f89"
    property color border: "#3b4261"
    property color bgPill: Qt.rgba(0.1, 0.1, 0.15, 0.97)
    property color bgHover: Qt.rgba(0.14, 0.16, 0.23, 0.97)
    property color accent: "#7aa2f7"
    property color accentSecondary: "#bb9af7"
    property color error: "#f7768e"
    property color warning: "#e0af68"
    property color success: "#9ece6a"
    property color info: "#7dcfff"
}
