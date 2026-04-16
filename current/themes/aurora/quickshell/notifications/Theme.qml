import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var _fv: FileView {
        path: Quickshell.env("HOME") + "/.config/theme/palette.conf"
        onLoadedChanged: if (loaded) root._parse()
    }

    property var _watcher: Process {
        running: true
        command: ["inotifywait", "-m", "-q", "-e", "close_write,moved_to", "--format", "%f",
                  Quickshell.env("HOME") + "/.config/theme"]
        stdout: SplitParser { onRead: data => { if (data.trim() === "palette.conf") root._parse() } }
        onRunningChanged: { if (!running) running = true }
    }

    function _parse() {
        var content = _fv.text()
        if (!content || content.length === 0) return
        var map = {}
        var lines = content.split('\n')
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line && line[0] !== '#' && line.indexOf('=') > 0) {
                var eq = line.indexOf('=')
                map[line.substring(0, eq).trim()] = '#' + line.substring(eq + 1).trim()
            }
        }
        function c(k, fb) { return map[k] || (fb ? map[fb] : null) || "#ff00ff" }
        function h(hex, a) { var s = hex.replace("#",""); return Qt.rgba(parseInt(s.substring(0,2),16)/255, parseInt(s.substring(2,4),16)/255, parseInt(s.substring(4,6),16)/255, a) }

        bg = h(c("bg"), 0.96)
        bgCard = c("bg")
        bgHighlight = c("bg_highlight")
        fg = c("fg")
        fgDim = c("fg_dim")
        fgMuted = c("fg_muted")
        accent = c("accent", "green")
        error = c("error", "red")
        border = Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)
        borderCritical = Qt.rgba(root.error.r, root.error.g, root.error.b, 0.4)
    }

    property color bg: "#1a1b2688"
    property color bgCard: "#1a1b26"
    property color bgHighlight: "#3b4261"
    property color fg: "#c0caf5"
    property color fgDim: "#a9b1d6"
    property color fgMuted: "#565f89"
    property color accent: "#7aa2f7"
    property color error: "#f7768e"
    property color border: "#32364a"
    property color borderCritical: "#f7768e66"
}
