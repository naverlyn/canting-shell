import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit
import QtQuick
import "../ThemeSwitcher" as TS
import "Components"

Scope {
    id: root

    TS.DefaultTheme { id: defaultTheme }
    property var theme: defaultTheme
    property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"

    property bool previewMode: false
    property bool submitting: false

    readonly property bool overlayActive: agent.isActive || root.previewMode

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            root.previewMode = false;
            root.submitting = false;
        }
    }

    Connections {
        target: agent.flow

        function onAuthenticationFailed() {
            root.submitting = false;
            if (overlayLoader.item) {
                overlayLoader.item.shakeOnError();
            }
        }

        function onIsResponseRequiredChanged() {
            if (agent.flow && agent.flow.isResponseRequired) {
                root.submitting = false;
                if (overlayLoader.item) {
                    overlayLoader.item.clearAndFocus();
                }
            }
        }
    }

    IpcHandler {
        target: "polkit"

        function test() {
            root.submitting = false;
            root.previewMode = !root.previewMode;
        }

        function close() {
            root.previewMode = false;
            if (agent.isActive && agent.flow) {
                agent.flow.cancelAuthenticationRequest();
            }
        }

        function status(): string {
            return agent.isRegistered ? "registered" : "unregistered";
        }
    }

    Loader {
        id: overlayLoader
        active: root.overlayActive
        sourceComponent: PolkitOverlay {
            theme: root.theme || defaultTheme
            font: root.font

            actionId: root.previewMode
                ? "org.freedesktop.policykit.exec"
                : (agent.flow ? agent.flow.actionId : "")
            message: root.previewMode
                ? "Authentication is required to run `/usr/bin/gparted` as the super user"
                : (agent.flow ? agent.flow.message : "")
            inputPrompt: root.previewMode
                ? "Password:"
                : (agent.flow ? agent.flow.inputPrompt : "")
            responseRequired: root.previewMode
                ? true
                : (agent.flow ? agent.flow.isResponseRequired : true)
            responseVisible: root.previewMode
                ? false
                : (agent.flow ? agent.flow.responseVisible : false)
            supplementaryMessage: root.previewMode
                ? ""
                : (agent.flow ? agent.flow.supplementaryMessage : "")
            supplementaryIsError: root.previewMode
                ? false
                : (agent.flow ? agent.flow.supplementaryIsError : false)
            failed: root.previewMode
                ? false
                : (agent.flow ? agent.flow.failed : false)
            identities: root.previewMode
                ? []
                : (agent.flow ? agent.flow.identities : [])
            selectedIdentity: root.previewMode
                ? null
                : (agent.flow ? agent.flow.selectedIdentity : null)
            submitting: root.submitting

            onIdentitySelected: (idObj) => {
                if (!root.previewMode && agent.flow) {
                    agent.flow.selectedIdentity = idObj;
                }
            }

            onSubmitted: (password) => {
                if (root.previewMode) {
                    root.previewMode = false;
                    return;
                }
                if (agent.flow) {
                    root.submitting = true;
                    agent.flow.submit(password);
                }
            }

            onCancelled: {
                root.submitting = false;
                if (root.previewMode) {
                    root.previewMode = false;
                    return;
                }
                if (agent.flow) {
                    agent.flow.cancelAuthenticationRequest();
                }
            }
        }
    }
}
