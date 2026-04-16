//@ pragma UseQApplication
import Quickshell
import Quickshell.Hyprland
import QtQuick
import "notifications"
import "osd"
import "session"
import "launcher"
// import "lockscreen"  // disabled — PAM auth needs fixing

Scope {
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    NotificationPopup {}
    OSD {}
    SessionMenu {}
    AppLauncher {}
    // LockScreen {}  // disabled for now
}
