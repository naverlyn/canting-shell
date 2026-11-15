import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: polkitWindow

    required property var theme
    required property string font
    required property string actionId
    required property string message
    required property string inputPrompt
    required property bool responseRequired
    required property bool responseVisible
    required property string supplementaryMessage
    required property bool supplementaryIsError
    required property bool failed
    required property var identities
    required property var selectedIdentity
    required property bool submitting

    signal identitySelected(var identity)
    signal submitted(string password)
    signal cancelled()

    function clearAndFocus() {
        authForm.clearInput();
        authForm.focusInput();
    }

    function shakeOnError() {
        authForm.clearInput();
        authForm.triggerShake();
        authForm.focusInput();
    }

    visible: true
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-polkit"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Component.onCompleted: {
        Qt.callLater(() => authForm.focusInput());
        openAnim.start();
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: card; property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "scale"; from: 0.96; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
    }

    Item {
        id: overlayRoot
        anchors.fill: parent

        // Undimmed transparent backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: polkitWindow.cancelled()
        }

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: polkitWindow.cancelled()

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: polkitWindow.width > 0 ? Math.min(460, polkitWindow.width - 48) : 460
                height: cardCol.implicitHeight + 48
                radius: 16
                color: polkitWindow.theme.bgBase
                border.width: 1
                border.color: polkitWindow.theme.bgBorder
                opacity: 0.0
                scale: 0.96

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: cardCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 24
                    }
                    spacing: 18

                    PolkitHeader {
                        theme: polkitWindow.theme
                        font: polkitWindow.font
                        actionId: polkitWindow.actionId
                        onCloseRequested: polkitWindow.cancelled()
                    }

                    PolkitAuthForm {
                        id: authForm
                        theme: polkitWindow.theme
                        font: polkitWindow.font
                        message: polkitWindow.message
                        inputPrompt: polkitWindow.inputPrompt
                        responseRequired: polkitWindow.responseRequired
                        responseVisible: polkitWindow.responseVisible
                        supplementaryMessage: polkitWindow.supplementaryMessage
                        supplementaryIsError: polkitWindow.supplementaryIsError
                        failed: polkitWindow.failed
                        identities: polkitWindow.identities
                        selectedIdentity: polkitWindow.selectedIdentity
                        submitting: polkitWindow.submitting

                        onIdentitySelected: (idObj) => polkitWindow.identitySelected(idObj)
                        onSubmitted: (pwd) => polkitWindow.submitted(pwd)
                        onCancelled: polkitWindow.cancelled()
                    }
                }
            }
        }
    }
}
