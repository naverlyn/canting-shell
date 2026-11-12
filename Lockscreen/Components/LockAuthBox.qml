import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."

Item {
    id: authRoot

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property string username: Quickshell.env("USER") || "User"
    property bool isAuthenticating: false
    property bool isSuccess: false
    property bool failActive: false
    property string errorMessage: ""
    property bool capsLockOn: false

    property real failFlashAlpha: 0.0
    property real failIconScale: 1.0
    property real successFlashAlpha: 0.0
    property real rippleScale: 0.85
    property real rippleOpacity: 0.0
    property real boxSuccessScale: 1.0
    property real boxSuccessOpacity: 1.0

    scale: boxSuccessScale
    opacity: boxSuccessOpacity

    signal submit(string password)

    function resolveColor(colStr, fallbackColor) {
        const t = authRoot.theme;
        if (!colStr) return fallbackColor;
        const str = String(colStr).trim();
        if (str.startsWith("#")) return str;
        if (str === "$accent" || str === "$accentPrimary" || str === "$mauve" || str === "$pink" || str === "$color5" || str === "$color13") return t.accentPrimary;
        if (str === "$blue" || str === "$cyan" || str === "$sapphire" || str === "$sky" || str === "$lavender" || str === "$color4" || str === "$color6" || str === "$color12") return t.accentCyan;
        if (str === "$green" || str === "$teal" || str === "$color2" || str === "$color14") return t.accentGreen;
        if (str === "$yellow" || str === "$orange" || str === "$peach" || str === "$color3" || str === "$color11") return t.accentOrange;
        if (str === "$red" || str === "$maroon" || str === "$flamingo" || str === "$color1" || str === "$color9") return t.accentRed;
        if (str === "$text" || str === "$rosewater" || str === "$color15" || str === "$foreground") return t.textPrimary;
        if (str === "$secondary" || str === "$subtext1" || str === "$color10" || str === "$color7") return t.textSecondary;
        if (str === "$muted" || str === "$subtext0" || str === "$overlay2" || str === "$color8") return t.textMuted;
        if (str === "$surface2" || str === "$overlay1") return t.bgSelected;
        if (str === "$surface1" || str === "$overlay0") return t.bgHover;
        if (str === "$surface0" || str === "$color0") return t.bgSurface;
        if (str === "$base" || str === "$mantle" || str === "$crust" || str === "$background") return t.bgBase;
        return fallbackColor;
    }

    readonly property color resolvedOuter: resolveColor(LockscreenConfig.input_outer_color, authRoot.theme.accentPrimary)
    readonly property color resolvedInner: resolveColor(LockscreenConfig.input_inner_color, authRoot.theme.bgSurface)
    readonly property color resolvedFont: resolveColor(LockscreenConfig.input_font_color, authRoot.theme.textPrimary)

    function clear() {
        pwdInput.text = "";
        errorMessage = "";
        failActive = false;
        isSuccess = false;
        failFlashAlpha = 0.0;
        successFlashAlpha = 0.0;
        rippleOpacity = 0.0;
        boxSuccessScale = 1.0;
        boxSuccessOpacity = 1.0;
    }

    function focusInput() {
        pwdInput.forceActiveFocus();
    }

    function triggerShake() {
        pwdInput.text = "";
        authRoot.failActive = true;
        failResetTimer.restart();
        shakeAnim.stop();
        shakeAnim.start();
    }

    function triggerSuccess() {
        pwdInput.text = "";
        authRoot.failActive = false;
        authRoot.errorMessage = "";
        authRoot.isSuccess = true;
        if (LockscreenConfig.unlock_animation) {
            successAnim.stop();
            successAnim.start();
        }
    }

    Timer {
        id: failResetTimer
        interval: 2400
        repeat: false
        onTriggered: {
            authRoot.failActive = false;
            authRoot.errorMessage = "";
        }
    }

    ParallelAnimation {
        id: successAnim
        NumberAnimation { target: authRoot; property: "successFlashAlpha"; from: 0.0; to: 0.32; duration: 220; easing.type: Easing.OutQuad }
        NumberAnimation { target: authRoot; property: "rippleScale"; from: 0.85; to: 2.35; duration: 520; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: authRoot; property: "rippleOpacity"; from: 0.0; to: 0.85; duration: 90; easing.type: Easing.OutQuad }
            NumberAnimation { target: authRoot; property: "rippleOpacity"; from: 0.85; to: 0.0; duration: 430; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            NumberAnimation { target: authRoot; property: "boxSuccessScale"; from: 1.0; to: 1.06; duration: 180; easing.type: Easing.OutBack }
            NumberAnimation { target: authRoot; property: "boxSuccessScale"; from: 1.06; to: 0.92; duration: 340; easing.type: Easing.InCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 160 }
            NumberAnimation { target: authRoot; property: "boxSuccessOpacity"; from: 1.0; to: 0.0; duration: 360; easing.type: Easing.InQuad }
        }
    }

    implicitWidth: Math.max(260, LockscreenConfig.input_width + 20)
    implicitHeight: mainCol.implicitHeight

    ColumnLayout {
        id: mainCol
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(260, LockscreenConfig.input_width + 20)
        spacing: 16

        // Avatar Frame
        Item {
            visible: LockscreenConfig.showUser
            Layout.alignment: Qt.AlignHCenter
            width: 104
            height: 104

            // Expanding Success Shockwave Ring
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: width / 2
                color: "transparent"
                border.width: 2.5
                border.color: authRoot.theme.accentGreen
                scale: authRoot.rippleScale
                opacity: authRoot.rippleOpacity
                visible: opacity > 0
            }

            Rectangle {
                id: avatarBg
                anchors.fill: parent
                radius: width / 2
                color: authRoot.resolvedInner
                border.width: 3
                border.color: authRoot.isSuccess
                              ? authRoot.theme.accentGreen
                              : (authRoot.isAuthenticating
                                 ? authRoot.theme.accentCyan
                                 : (authRoot.errorMessage !== "" || authRoot.failActive
                                    ? authRoot.theme.accentRed
                                    : authRoot.resolvedOuter))

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }

                // Avatar Image (if ~/.face exists)
                Image {
                    id: faceImg
                    anchors.fill: parent
                    anchors.margins: 3
                    source: LockscreenConfig.faceIconPath !== "" ? ("file://" + LockscreenConfig.faceIconPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: status === Image.Ready
                    layer.enabled: true
                }

                // Fallback Avatar Icon
                Text {
                    anchors.centerIn: parent
                    visible: faceImg.status !== Image.Ready
                    text: "󰀉"
                    font.family: authRoot.font
                    font.pixelSize: 48
                    color: authRoot.resolvedOuter
                }
            }
        }

        // Username
        Text {
            visible: LockscreenConfig.showUser
            Layout.alignment: Qt.AlignHCenter
            text: authRoot.username
            font.family: authRoot.font
            font.pixelSize: 20
            font.bold: true
            color: authRoot.theme.textPrimary
            style: Text.Outline
            styleColor: authRoot.theme.bgOverlay
        }

        // Input Field with In-Box Failed & Success Animation
        Item {
            id: inputHolder
            Layout.alignment: Qt.AlignHCenter
            width: Math.max(240, LockscreenConfig.input_width)
            height: Math.max(44, LockscreenConfig.input_height)

            property real innerShakeX: 0

            ParallelAnimation {
                id: shakeAnim
                SequentialAnimation {
                    NumberAnimation { target: inputHolder; property: "innerShakeX"; to: -12; duration: 45; easing.type: Easing.OutQuad }
                    NumberAnimation { target: inputHolder; property: "innerShakeX"; to: 12; duration: 45; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: inputHolder; property: "innerShakeX"; to: -9; duration: 40; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: inputHolder; property: "innerShakeX"; to: 9; duration: 40; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: inputHolder; property: "innerShakeX"; to: -5; duration: 35; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: inputHolder; property: "innerShakeX"; to: 4; duration: 30; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: inputHolder; property: "innerShakeX"; to: 0; duration: 30; easing.type: Easing.InQuad }
                }
                SequentialAnimation {
                    NumberAnimation { target: authRoot; property: "failFlashAlpha"; from: 0.0; to: 0.30; duration: 70; easing.type: Easing.OutQuad }
                    NumberAnimation { target: authRoot; property: "failFlashAlpha"; to: 0.12; duration: 110; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: authRoot; property: "failFlashAlpha"; to: 0.24; duration: 70; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: authRoot; property: "failFlashAlpha"; to: 0.0; duration: 220; easing.type: Easing.OutCubic }
                }
                SequentialAnimation {
                    NumberAnimation { target: authRoot; property: "failIconScale"; from: 1.0; to: 1.28; duration: 85; easing.type: Easing.OutBack }
                    NumberAnimation { target: authRoot; property: "failIconScale"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                }
                onFinished: {
                    inputHolder.innerShakeX = 0;
                    authRoot.failFlashAlpha = 0.0;
                    authRoot.failIconScale = 1.0;
                    authRoot.focusInput();
                }
            }

            Rectangle {
                id: inputBoxRect
                anchors.fill: parent
                radius: 14
                clip: true
                color: Qt.rgba(authRoot.resolvedInner.r, authRoot.resolvedInner.g, authRoot.resolvedInner.b, 0.82)
                border.width: Math.max(1, LockscreenConfig.input_outline_thickness || (pwdInput.activeFocus ? 2 : 1))
                border.color: {
                    if (authRoot.isSuccess)
                        return authRoot.theme.accentGreen;
                    if (authRoot.errorMessage !== "" || authRoot.failActive)
                        return authRoot.theme.accentRed;
                    if (authRoot.isAuthenticating)
                        return authRoot.theme.accentCyan;
                    if (pwdInput.activeFocus || LockscreenConfig.input_outer_color)
                        return authRoot.resolvedOuter;
                    return authRoot.theme.bgBorder;
                }

                Behavior on border.color {
                    ColorAnimation { duration: 180 }
                }

                // In-Box Error Flash Overlay
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: authRoot.theme.accentRed
                    opacity: authRoot.failFlashAlpha
                    visible: opacity > 0
                }

                // In-Box Success Flash Overlay
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: authRoot.theme.accentGreen
                    opacity: authRoot.successFlashAlpha
                    visible: opacity > 0
                }

                RowLayout {
                    id: innerContentRow
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10
                    transform: Translate { x: inputHolder.innerShakeX }

                    // Left Lock / Status Icon
                    Text {
                        text: authRoot.isSuccess
                              ? ""
                              : (authRoot.isAuthenticating
                                 ? "󱥸"
                                 : ((authRoot.errorMessage !== "" || authRoot.failActive)
                                    ? "󰌾"
                                    : (pwdInput.text.length > 0 ? "󰌾" : "󰌿")))
                        font.family: authRoot.font
                        font.pixelSize: 18
                        scale: authRoot.failIconScale
                        color: authRoot.isSuccess
                               ? authRoot.theme.accentGreen
                               : ((authRoot.errorMessage !== "" || authRoot.failActive)
                                  ? authRoot.theme.accentRed
                                  : authRoot.resolvedOuter)

                        Behavior on color { ColorAnimation { duration: 160 } }

                        RotationAnimator on rotation {
                            running: authRoot.isAuthenticating
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1000
                        }
                    }

                    // Password Input (Pure keyboard handler to avoid multi-monitor QWaylandTextInputv3 surface conflicts)
                    FocusScope {
                        id: pwdInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        enabled: !authRoot.isAuthenticating && !authRoot.isSuccess
                        focus: true

                        property string text: ""
                        readonly property bool inputMethodComposing: false

                        onTextChanged: {
                            if (text.length > 0 && (authRoot.errorMessage !== "" || authRoot.failActive)) {
                                authRoot.errorMessage = "";
                                authRoot.failActive = false;
                                failResetTimer.stop();
                            }
                        }

                        function accepted() {
                            if (text.length > 0 && !authRoot.isAuthenticating && !authRoot.isSuccess) {
                                authRoot.errorMessage = "";
                                authRoot.failActive = false;
                                authRoot.submit(text);
                            }
                        }

                        Keys.onPressed: event => {
                            if (!pwdInput.enabled) return;

                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                pwdInput.accepted();
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Escape) {
                                pwdInput.text = "";
                                authRoot.errorMessage = "";
                                authRoot.failActive = false;
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Backspace) {
                                if (event.modifiers & Qt.ControlModifier) {
                                    pwdInput.text = "";
                                } else if (pwdInput.text.length > 0) {
                                    pwdInput.text = pwdInput.text.slice(0, -1);
                                }
                                event.accepted = true;
                                return;
                            }
                            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U) {
                                pwdInput.text = "";
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_CapsLock) {
                                authRoot.capsLockOn = !authRoot.capsLockOn;
                                event.accepted = true;
                                return;
                            }
                            if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
                                const c = event.text;
                                const isUpper = (c >= 'A' && c <= 'Z');
                                const isLower = (c >= 'a' && c <= 'z');
                                const shift = Boolean(event.modifiers & Qt.ShiftModifier);
                                if (isUpper && !shift) authRoot.capsLockOn = true;
                                if (isLower && shift) authRoot.capsLockOn = true;
                                if (isLower && !shift) authRoot.capsLockOn = false;
                                if (isUpper && shift) authRoot.capsLockOn = false;
                                pwdInput.text += c;
                                event.accepted = true;
                            }
                        }

                        // Masked Password Dots Display
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: pwdInput.text.length > 0
                            text: "●".repeat(pwdInput.text.length)
                            font.family: authRoot.font
                            font.pixelSize: 16
                            color: authRoot.resolvedFont
                            elide: Text.ElideLeft
                        }

                        // Placeholder / Status Text
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !pwdInput.text && !pwdInput.inputMethodComposing
                            text: authRoot.isSuccess
                                  ? "Unlocked"
                                  : ((authRoot.errorMessage !== "" || authRoot.failActive)
                                     ? (authRoot.errorMessage || "Authentication failed")
                                     : (authRoot.isAuthenticating ? "Verifying..." : (LockscreenConfig.input_placeholder || "Password...")))
                            font.family: authRoot.font
                            font.pixelSize: (authRoot.errorMessage !== "" || authRoot.failActive || authRoot.isSuccess) ? 14 : 15
                            font.italic: !(authRoot.errorMessage !== "" || authRoot.failActive || authRoot.isSuccess)
                            font.weight: (authRoot.errorMessage !== "" || authRoot.failActive || authRoot.isSuccess) ? Font.DemiBold : Font.Normal
                            color: authRoot.isSuccess
                                   ? authRoot.theme.accentGreen
                                   : ((authRoot.errorMessage !== "" || authRoot.failActive)
                                      ? authRoot.theme.accentRed
                                      : authRoot.theme.textMuted)
                            elide: Text.ElideRight

                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                    }

                    // Submit Arrow Button
                    Item {
                        width: 28
                        height: 28
                        visible: pwdInput.text.length > 0 && !authRoot.isAuthenticating && !authRoot.isSuccess

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: submitMouse.containsMouse
                                   ? authRoot.theme.accentPrimary
                                   : authRoot.theme.bgHover

                            Text {
                                anchors.centerIn: parent
                                text: "󰁔"
                                font.family: authRoot.font
                                font.pixelSize: 14
                                color: submitMouse.containsMouse ? authRoot.theme.bgBase : authRoot.theme.textPrimary
                            }

                            MouseArea {
                                id: submitMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: pwdInput.accepted()
                            }
                        }
                    }
                }
            }
        }

        // Caps Lock Notice Row
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            // Caps Lock Warning
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: authRoot.capsLockOn
                spacing: 6

                Text {
                    text: "󰪛"
                    font.family: authRoot.font
                    font.pixelSize: 14
                    color: authRoot.theme.accentOrange
                }

                Text {
                    text: "Caps Lock is ON"
                    font.family: authRoot.font
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: authRoot.theme.accentOrange
                }
            }
        }
    }
}
