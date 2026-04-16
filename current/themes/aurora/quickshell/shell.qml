//@ pragma UseQApplication
import Quickshell
import Quickshell.Hyprland
import QtQuick
import "notifications"
import "osd"
import "session"
import "launcher"

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
}
