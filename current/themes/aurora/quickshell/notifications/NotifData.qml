import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: root

    property Notification notification: null
    property bool closed: false
    property string seqId: ""
    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property string appName: ""
    property string image: ""
    property var actions: []
    property int urgency: NotificationUrgency.Normal
    property real expireTimeout: 5
    property bool hovered: false

    readonly property Connections _conn: Connections {
        target: root.notification
        function onClosed() {
            if (root.closed) return
            root.closed = true
            NotificationService._remove(root)
            root.destroy()
        }
    }

    readonly property Timer _timer: Timer {
        running: !root.closed && !root.hovered && root.urgency !== NotificationUrgency.Critical
        interval: root.expireTimeout * 1000
        onTriggered: root.dismiss()
    }

    Component.onCompleted: {
        if (!notification) return
        summary = notification.summary || ""
        body = notification.body || ""
        appIcon = notification.appIcon || ""
        appName = notification.appName || ""
        image = notification.image || ""
        urgency = notification.urgency
        expireTimeout = notification.expireTimeout > 0 ? notification.expireTimeout : 5
        actions = []
        for (var i = 0; i < notification.actions.length; i++) {
            actions.push({ identifier: notification.actions[i].identifier, text: notification.actions[i].text })
        }
    }

    function dismiss() {
        if (closed) return
        closed = true
        NotificationService._remove(root)
        try { notification.dismiss() } catch(e) {}
        destroy()
    }

    function invokeAction(identifier) {
        if (!identifier || closed) return
        closed = true
        NotificationService._remove(root)
        for (var i = 0; i < notification.actions.length; i++) {
            if (notification.actions[i].identifier === identifier) {
                try { notification.actions[i].invoke() } catch(e) {}
                break
            }
        }
        destroy()
    }
}
