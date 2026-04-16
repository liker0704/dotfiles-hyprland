//@ pragma UseQApplication
import Quickshell
import Quickshell.Hyprland
import QtQuick
import "notifications"

Scope {
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    // Notification toasts (replaces swaync)
    NotificationPopup {}
}
