pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property list<var> notifications: []
    property bool doNotDisturb: false
    readonly property int count: notifications.length
    property int _seq: 0

    Component { id: notifComp; NotifData {} }

    NotificationServer {
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: function(notification) {
            if (root.doNotDisturb) return
            if (!notification.summary && !notification.body) return

            notification.tracked = true

            // Replace existing with same id
            var idStr = String(notification.id || "")
            if (idStr) {
                for (var i = 0; i < root.notifications.length; i++) {
                    if (String(root.notifications[i].notification?.id || "") === idStr) {
                        root.notifications[i].closed = true
                        root.notifications[i].destroy()
                        root.notifications.splice(i, 1)
                        break
                    }
                }
            }

            var data = notifComp.createObject(root, {
                notification: notification,
                seqId: String(root._seq++)
            })
            root.notifications = [data, ...root.notifications]

            // Cap at 5
            while (root.notifications.length > 5) {
                root.notifications[root.notifications.length - 1].dismiss()
            }
        }
    }

    function _remove(notifData) {
        root.notifications = root.notifications.filter(function(n) { return n !== notifData })
    }

    function dismissAll() {
        var all = root.notifications.slice()
        root.notifications = []
        for (var i = 0; i < all.length; i++) {
            all[i].closed = true
            try { all[i].notification.dismiss() } catch(e) {}
            all[i].destroy()
        }
    }
}
