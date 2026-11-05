import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root

    property var theme: DefaultTheme {}
    property bool isLocked: false
    property bool isAuthenticating: false
    property bool isUnlocking: false
    property string errorMessage: ""
    property string submittedPassword: ""

    signal authFailed()
    signal authSucceeded()

    Timer {
        id: unlockFinishTimer
        interval: 540
        repeat: false
        onTriggered: {
            root.isUnlocking = false;
            root.isLocked = false;
        }
    }

    function startAuth(password) {
        if (!password || password.length === 0 || root.isAuthenticating || root.isUnlocking) return;

        root.isAuthenticating = true;
        root.errorMessage = "";
        root.submittedPassword = password;

        const ok = pam.start();
        if (!ok) {
            root.isAuthenticating = false;
            root.errorMessage = "Failed to start PAM verification";
            root.submittedPassword = "";
            root.authFailed();
        }
    }

    function triggerFailure() {
        root.authFailed();
    }

    Process {
        id: screenshotProc
        command: ["grim", "/tmp/lockscreen_screenshot.png"]
        running: false
        onExited: {
            root.isLocked = true;
        }
    }

    // IPC Endpoint to allow external scripts, hypridle, and keybinds to trigger lock/unlock
    IpcHandler {
        target: "lockscreen"

        function lock() {
            unlockFinishTimer.stop();
            root.isUnlocking = false;
            root.errorMessage = "";
            root.submittedPassword = "";
            root.isAuthenticating = false;
            if (LockscreenConfig.background_source === "screenshot") {
                screenshotProc.running = true;
            } else {
                root.isLocked = true;
            }
        }

        function unlock() {
            unlockFinishTimer.stop();
            if (pam.active) pam.abort();
            root.isUnlocking = false;
            root.isLocked = false;
            root.isAuthenticating = false;
            root.errorMessage = "";
            root.submittedPassword = "";
        }

        function toggle() {
            if (root.isLocked) unlock();
            else lock();
        }

        function status() {
            return root.isLocked ? "locked" : "unlocked";
        }
    }

    // PAM Authentication Manager
    PamContext {
        id: pam
        config: "login"
        user: Quickshell.env("USER") || ""

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(root.submittedPassword);
            }
        }

        onCompleted: result => {
            root.isAuthenticating = false;
            root.submittedPassword = "";

            if (result === PamResult.Success) {
                root.errorMessage = "";
                if (LockscreenConfig.unlock_animation) {
                    root.isUnlocking = true;
                    root.authSucceeded();
                    unlockFinishTimer.restart();
                } else {
                    root.isLocked = false;
                }
            } else {
                root.errorMessage = (pam.message && pam.message.length > 0)
                                    ? pam.message
                                    : "Authentication failed";
                root.triggerFailure();
            }
        }

        onError: err => {
            root.isAuthenticating = false;
            root.submittedPassword = "";
            root.errorMessage = "PAM Error: " + PamError.toString(err);
            root.triggerFailure();
        }
    }

    // Wayland Session Lock Protocol Controller
    WlSessionLock {
        id: sessionLock
        locked: root.isLocked

        surface: Component {
            WlSessionLockSurface {
                id: surfaceInst

                LockSurfaceView {
                    id: view
                    theme: root.theme
                    isAuthenticating: root.isAuthenticating
                    errorMessage: root.errorMessage

                    onSubmitPassword: pwd => root.startAuth(pwd)

                    Connections {
                        target: root
                        function onAuthFailed() {
                            view.triggerShake();
                        }
                        function onAuthSucceeded() {
                            view.triggerSuccess();
                        }
                    }
                }
            }
        }
    }
}
