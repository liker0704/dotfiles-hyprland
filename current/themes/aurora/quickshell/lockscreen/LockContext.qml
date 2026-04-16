import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    signal unlocked()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentText === "") return
        unlockInProgress = true
        showFailure = false
        pam.start()
    }

    PamContext {
        id: pam
        // Uses /etc/pam.d/quickshell (default configDirectory = /etc/pam.d)
        config: "quickshell"

        onPamMessage: function(msg, isError) {
            if (responseRequired) respond(root.currentText)
        }

        onCompleted: function(result) {
            if (result === PamResult.Success) {
                root.unlocked()
            } else {
                root.currentText = ""
                root.showFailure = true
            }
            root.unlockInProgress = false
        }
    }
}
