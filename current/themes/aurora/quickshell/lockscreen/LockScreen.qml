import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import ".."

Scope {
    id: root

    LockContext {
        id: lockContext
        onUnlocked: {
            lock.locked = false
        }
    }

    WlSessionLock {
        id: lock
        locked: false

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock() {
            lockContext.currentText = ""
            lockContext.showFailure = false
            root.doLock()
        }
    }

    function doLock() {
        lock.locked = true
    }

    // Listen for loginctl lock-session signal
    Connections {
        target: lock
        function onLockedChanged() {
            if (!lock.locked) {
                lockContext.currentText = ""
                lockContext.showFailure = false
            }
        }
    }
}
