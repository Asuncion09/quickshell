pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pam
import "../theme"

Item {
    id: root

    property bool isLocked: false
    property bool isUnlocking: false
    property bool isAuthenticating: false
    property bool authFailed: false
    property bool authSucceeded: false
    property string errorMessage: ""

    property string pendingPassword: ""

    // Contexto nativo de autenticación PAM de Linux
    PamContext {
        id: pam
        user: Quickshell.env("USER")
        config: "hyprlock"

        onResponseRequiredChanged: {
            if (responseRequired && root.pendingPassword !== "") {
                let pwd = root.pendingPassword;
                root.pendingPassword = "";
                pam.respond(pwd);
            }
        }

        onCompleted: result => {
            root.isAuthenticating = false;
            if (result === PamResult.Success) {
                root.authFailed = false;
                root.authSucceeded = true;
                root.errorMessage = "";
                root.triggerUnlockAnimation();
            } else {
                root.authFailed = true;
                root.authSucceeded = false;
                root.errorMessage = "Contraseña incorrecta";
                restartPamTimer.restart();
            }
        }

        onError: err => {
            root.isAuthenticating = false;
            root.authFailed = true;
            root.authSucceeded = false;
            root.errorMessage = PamError.toString(err);
            restartPamTimer.restart();
        }
    }

    Timer {
        id: restartPamTimer
        interval: 600
        onTriggered: {
            root.authFailed = false;
            if (root.isLocked && !pam.active) {
                pam.start();
            }
        }
    }

    Timer {
        id: unlockFinishTimer
        interval: 240
        onTriggered: {
            root.isLocked = false;
            root.isUnlocking = false;
            root.isAuthenticating = false;
            root.authFailed = false;
            root.authSucceeded = false;
            root.errorMessage = "";
            root.pendingPassword = "";
        }
    }

    function triggerUnlockAnimation() {
        root.authSucceeded = true;
        root.isUnlocking = true;
        unlockFinishTimer.restart();
    }

    function lock() {
        if (root.isLocked) return;
        root.isLocked = true;
        root.isUnlocking = false;
        root.authFailed = false;
        root.authSucceeded = false;
        root.isAuthenticating = false;
        root.errorMessage = "";
        root.pendingPassword = "";

        if (pam.active) pam.abort();
        pam.start();
    }

    function submitPassword(password) {
        if (!root.isLocked || root.isAuthenticating || root.isUnlocking) return;
        if (!password || password.length === 0) return;

        root.isAuthenticating = true;
        root.authFailed = false;
        root.errorMessage = "";

        if (pam.responseRequired) {
            pam.respond(password);
        } else {
            root.pendingPassword = password;
            if (!pam.active) {
                pam.start();
            }
        }
    }
}
