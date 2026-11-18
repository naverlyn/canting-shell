import Quickshell
import Quickshell.Io
import QtQuick
import "Components"

Scope {
    id: root

    property var theme: Theme
    property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"
    property bool panelVisible: false
    property string selectedPreset: "laptop"
    property var detectedTools: ({})

    readonly property string scriptPath: Quickshell.shellPath("SetupWizard/scripts/setup_wizard.py")

    function openWizard() {
        statusProc.openIfNotDone = false;
        statusProc.running = true;
        root.panelVisible = true;
    }

    function finishWizard() {
        markDoneProc.running = true;
        root.panelVisible = false;
    }

    function applyPreset(name) {
        root.selectedPreset = name;
        applyPresetProc.command = ["python3", root.scriptPath, "apply_preset", name];
        applyPresetProc.running = true;
    }

    function finishAndLaunch(target, fnName, arg) {
        markDoneProc.running = true;
        root.panelVisible = false;
        if (arg !== undefined && arg !== "") {
            launchIpcProc.command = ["qs", "ipc", "call", target, fnName, arg];
        } else {
            launchIpcProc.command = ["qs", "ipc", "call", target, fnName];
        }
        launchIpcProc.running = true;
    }

    IpcHandler {
        target: "setup"

        function open() {
            root.openWizard();
        }

        function close() {
            root.panelVisible = false;
        }

        function toggle() {
            if (root.panelVisible) {
                root.panelVisible = false;
            } else {
                root.openWizard();
            }
        }
    }

    Process {
        id: statusProc
        property bool openIfNotDone: true
        command: ["python3", root.scriptPath, "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim() || "{}");
                    root.detectedTools = data.tools || {};
                    if (statusProc.openIfNotDone && data.done === false) {
                        root.panelVisible = true;
                    }
                } catch (e) {
                    console.warn("SetupWizard: failed to parse status:", e);
                }
            }
        }
    }

    Process {
        id: applyPresetProc
        running: false
    }

    Process {
        id: markDoneProc
        command: ["python3", root.scriptPath, "mark_done"]
        running: false
    }

    Process {
        id: launchIpcProc
        running: false
    }

    Component.onCompleted: {
        statusProc.openIfNotDone = true;
        statusProc.running = true;
    }

    Loader {
        active: root.panelVisible
        sourceComponent: Component {
            SetupWizardWindow {
                theme: root.theme
                font: root.font
                selectedPreset: root.selectedPreset
                detectedTools: root.detectedTools
                onPresetChosen: name => root.applyPreset(name)
                onFinishRequested: root.finishWizard()
                onSkipRequested: root.finishWizard()
                onLaunchIpcRequested: (target, fnName, arg) => root.finishAndLaunch(target, fnName, arg)
            }
        }
    }
}
