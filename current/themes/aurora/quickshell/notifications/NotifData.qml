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
    // Wall-clock timestamp of creation — used by progress bar delegate to
    // compute remaining time. Survives delegate recreation (when Repeater
    // rebuilds on new notifications) so the bar doesn't reset.
    // MUST be initialized via property initializer (runs at construction)
    // not Component.onCompleted — otherwise delegate reads 0 in the same
    // event-loop pass before onCompleted fires.
    property real createdAt: Date.now()

    readonly property Connections _conn: Connections {
        target: root.notification
        function onClosed() {
            if (root.closed) return
            root.closed = true
            NotificationService._remove(root)
            root.destroy()
        }
    }

    // Timer must NOT pause on hover — Qt Timer restarts from 0 when running
    // toggles true→false→true, so the old notification's countdown gets reset
    // whenever mouse hovers (incl. when a new notification appears at the same
    // spot and the cursor is there). Result: old notifs stayed forever.
    //
    // Started explicitly from Component.onCompleted (not via declarative
    // `running:` binding) — when expireTimeout was bound declaratively the
    // timer never fired in practice, leaving notifs onscreen indefinitely.
    readonly property Timer _timer: Timer {
        repeat: false
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
        // Spec: notification.expireTimeout is in milliseconds. Our internal
        // `expireTimeout` property is in seconds (everything downstream — the
        // progress bar, the Timer interval — multiplies by 1000).
        expireTimeout = notification.expireTimeout > 0 ? notification.expireTimeout / 1000 : 5
        actions = []
        for (var i = 0; i < notification.actions.length; i++) {
            actions.push({ identifier: notification.actions[i].identifier, text: notification.actions[i].text })
        }
        if (urgency !== NotificationUrgency.Critical) {
            _timer.interval = expireTimeout * 1000
            _timer.start()
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
