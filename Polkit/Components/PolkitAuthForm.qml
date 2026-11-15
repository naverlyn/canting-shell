import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var theme
    required property string font
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

    property bool showPassword: false
    property real shakeOffset: 0

    function focusInput() {
        passInput.forceActiveFocus();
    }

    function clearInput() {
        passInput.text = "";
    }

    function triggerShake() {
        shakeAnim.restart();
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: root; property: "shakeOffset"; to: -8; duration: 45 }
        NumberAnimation { target: root; property: "shakeOffset"; to: 8; duration: 45 }
        NumberAnimation { target: root; property: "shakeOffset"; to: -6; duration: 45 }
        NumberAnimation { target: root; property: "shakeOffset"; to: 6; duration: 45 }
        NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 45 }
    }

    Layout.fillWidth: true
    spacing: 14

    // Request Message Callout
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: msgText.implicitHeight + 22
        radius: 12
        color: root.theme.bgSurface
        border.width: 1
        border.color: root.theme.bgBorder

        Text {
            id: msgText
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 14
            }
            text: root.message !== "" ? root.message : "An application is requesting elevated privileges."
            font.family: root.font
            font.pixelSize: 13
            color: root.theme.textPrimary
            wrapMode: Text.WordWrap
            lineHeight: 1.3
        }
    }

    // Identity Selector (only when multiple identities are available)
    RowLayout {
        Layout.fillWidth: true
        visible: root.identities && root.identities.length > 1
        spacing: 8

        Text {
            text: "User:"
            font.family: root.font
            font.pixelSize: 12
            color: root.theme.textSecondary
        }

        Repeater {
            model: root.identities || []

            delegate: Rectangle {
                required property var modelData
                readonly property bool active: root.selectedIdentity === modelData
                readonly property string label: (modelData && (modelData.displayName || modelData.name)) || "User"

                implicitWidth: idLbl.implicitWidth + 20
                implicitHeight: 28
                radius: 8
                color: active
                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                    : root.theme.bgSurface
                border.width: 1
                border.color: active ? root.theme.accentPrimary : root.theme.bgBorder

                Text {
                    id: idLbl
                    anchors.centerIn: parent
                    text: label
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: active
                    color: active ? root.theme.accentPrimary : root.theme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.identitySelected(modelData)
                }
            }
        }
    }

    // Password Input Box
    Rectangle {
        id: inputBox
        visible: root.responseRequired
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: 12
        color: root.theme.bgSurface
        border.width: (passInput.activeFocus || root.failed) ? 2 : 1
        border.color: root.failed
            ? root.theme.accentRed
            : (passInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder)
        transform: Translate { x: root.shakeOffset }

        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: "󰌆"
                font.family: root.font
                font.pixelSize: 15
                color: passInput.activeFocus ? root.theme.accentPrimary : root.theme.textMuted
            }

            TextInput {
                id: passInput
                Layout.fillWidth: true
                enabled: !root.submitting
                color: root.theme.textPrimary
                selectionColor: root.theme.accentPrimary
                selectedTextColor: root.theme.bgBase
                font.family: root.font
                font.pixelSize: 13
                echoMode: (root.responseVisible || root.showPassword) ? TextInput.Normal : TextInput.Password
                passwordCharacter: "•"
                clip: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.inputPrompt !== "" ? root.inputPrompt : "Enter password..."
                    font.family: root.font
                    font.pixelSize: 13
                    color: root.theme.textMuted
                    visible: passInput.text.length === 0
                }

                Keys.onReturnPressed: root.submitted(passInput.text)
                Keys.onEnterPressed: root.submitted(passInput.text)
                Keys.onEscapePressed: root.cancelled()
            }

            // Show/Hide Password Toggle
            Rectangle {
                visible: !root.responseVisible
                width: 28
                height: 28
                radius: 8
                color: eyeMouse.containsMouse ? root.theme.bgHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: root.showPassword ? "󰈉" : "󰈈"
                    font.family: root.font
                    font.pixelSize: 14
                    color: root.theme.textSecondary
                }

                MouseArea {
                    id: eyeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showPassword = !root.showPassword
                }
            }
        }
    }

    // Error / Supplementary Feedback
    Text {
        Layout.fillWidth: true
        visible: root.supplementaryMessage !== "" || root.failed
        text: root.supplementaryMessage !== ""
            ? root.supplementaryMessage
            : "Authentication failed. Please try again."
        font.family: root.font
        font.pixelSize: 12
        color: (root.supplementaryIsError || root.failed) ? root.theme.accentRed : root.theme.textSecondary
        wrapMode: Text.WordWrap
    }

    // Action Buttons
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Item { Layout.fillWidth: true }

        Rectangle {
            implicitWidth: cancelLbl.implicitWidth + 28
            implicitHeight: 36
            radius: 10
            color: cancelMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
            border.width: 1
            border.color: root.theme.bgBorder
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: cancelLbl
                anchors.centerIn: parent
                text: "Cancel (Esc)"
                font.family: root.font
                font.pixelSize: 12
                color: root.theme.textSecondary
            }

            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cancelled()
            }
        }

        Rectangle {
            readonly property bool canSubmit: !root.submitting && (!root.responseRequired || passInput.text.length > 0)
            implicitWidth: authLbl.implicitWidth + 28
            implicitHeight: 36
            radius: 10
            opacity: canSubmit ? 1.0 : 0.5
            color: authMouse.containsMouse && canSubmit
                ? Qt.lighter(root.theme.accentPrimary, 1.1)
                : root.theme.accentPrimary
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: authLbl
                anchors.centerIn: parent
                text: root.submitting ? "Verifying..." : "Authenticate"
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.bgBase
            }

            MouseArea {
                id: authMouse
                anchors.fill: parent
                enabled: parent.canSubmit
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submitted(passInput.text)
            }
        }
    }
}
