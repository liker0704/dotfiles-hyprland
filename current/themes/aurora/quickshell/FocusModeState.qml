pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool active: false
    readonly property string _stateDir: Quickshell.env("HOME") + "/.config/focus-mode"

    property Process _check: Process {
        running: true
        command: ["bash", "-c", "[ -f \"$HOME/.config/focus-mode/state\" ] && echo on || echo off"]
        stdout: SplitParser { onRead: data => { root.active = (data.trim() === "on") } }
    }

    property Process _watcher: Process {
        running: true
        command: ["bash", "-c",
            "mkdir -p \"$HOME/.config/focus-mode\"; " +
            "exec inotifywait -m -q -e create,delete,moved_to,moved_from " +
            "--format '%f:%e' \"$HOME/.config/focus-mode\""]
        stdout: SplitParser { onRead: data => {
            if (data.indexOf("state:") === 0) root._check.running = true
        }}
        onRunningChanged: { if (!running) running = true }
    }
}
