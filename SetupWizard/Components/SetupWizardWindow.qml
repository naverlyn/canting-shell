import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var theme
    required property string font
    required property string selectedPreset
    required property var detectedTools
    required property var detectedHardware
    required property string scriptPath

    signal presetChosen(string name)
    signal finishRequested()
    signal skipRequested()
    signal refreshToolsRequested()
    signal launchIpcRequested(string target, string fnName, string arg)

    property int step: 0
    property bool closing: false
    property var pendingCloseAction: null
    readonly property var stepTitles: ["Choose Preset", "Theme & Wallpaper", "Lockscreen", "Display & Input", "Shortcuts", "Optional Tools", "Default Apps"]

    function closeWith(action) {
        if (root.closing) return;
        root.closing = true;
        root.pendingCloseAction = action || null;
        openAnim.stop();
        closeAnim.start();
    }

    onStepChanged: {
        themeStep.subView = "main";
        presetStep.customizingBar = false;
        shortcutsStep.customizingShortcuts = false;
        stepAnim.restart();
    }

    Component.onCompleted: openAnim.start()

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: backdrop; property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "scale"; from: 0.96; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: backdrop; property: "opacity"; to: 0.0; duration: 120; easing.type: Easing.InCubic }
        NumberAnimation { target: card; property: "opacity"; to: 0.0; duration: 110; easing.type: Easing.InCubic }
        NumberAnimation { target: card; property: "scale"; to: 0.96; duration: 110; easing.type: Easing.InCubic }
        onFinished: {
            if (root.pendingCloseAction) root.pendingCloseAction();
        }
    }

    ParallelAnimation {
        id: stepAnim
        NumberAnimation { target: stepContentWrap; property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: stepContentWrap; property: "y"; from: 8; to: 0; duration: 160; easing.type: Easing.OutCubic }
    }

    visible: true
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-setup-wizard"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Dimmed backdrop
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#66000000"
        opacity: 0.0
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeWith(() => root.skipRequested())
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.closeWith(() => root.skipRequested())
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        readonly property bool isExpanded: (presetStep.customizingBar && root.step === 0)
            || (root.step === 1 && themeStep.subView !== "main")
            || (root.step === 2)
            || (root.step === 3)
            || (shortcutsStep.customizingShortcuts && root.step === 4)
            || (root.step === 6)
        readonly property bool isShortcutsWithLegend: shortcutsStep.customizingShortcuts && root.step === 4 && shortcutsStep.showIpcLegend
        width: Math.min(isExpanded ? (isShortcutsWithLegend ? 1160 : 960) : 760, root.width - 48)
        height: Math.min(isExpanded ? 680 : 580, root.height - 48)
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        radius: 18
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        clip: true
        opacity: 0.0
        scale: 0.96

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: "Welcome to canting-shell"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "configure your initial setup in a few clicks."
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    radius: 8
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder
                    border.width: 1
                    implicitWidth: stepBadge.implicitWidth + 16
                    implicitHeight: 28

                    Text {
                        id: stepBadge
                        anchors.centerIn: parent
                        text: root.stepTitles[root.step]
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }
            }

            // Step indicator bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.stepTitles.length
                    delegate: Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: index <= root.step ? root.theme.accentPrimary : root.theme.bgBorder
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Step content
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Item {
                    id: stepContentWrap
                    width: parent.width
                    height: parent.height

                    StackLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        currentIndex: root.step

                        SetupPresetStep {
                            id: presetStep
                            theme: root.theme
                            font: root.font
                            selectedPreset: root.selectedPreset
                            onPresetChosen: name => root.presetChosen(name)
                            onCustomizingBarChanged: stepAnim.restart()
                        }

                        SetupThemeStep {
                            id: themeStep
                            theme: root.theme
                            font: root.font
                            onSubViewChanged: stepAnim.restart()
                        }

                        SetupLockscreenStep {
                            theme: root.theme
                            font: root.font
                            isActive: root.step === 2
                        }

                        SetupDisplayInputStep {
                            theme: root.theme
                            font: root.font
                            isActive: root.step === 3
                        }

                        SetupShortcutsStep {
                            id: shortcutsStep
                            theme: root.theme
                            font: root.font
                            onCustomizingShortcutsChanged: stepAnim.restart()
                        }

                        SetupDefaultAppsStep {
                            theme: root.theme
                            font: root.font
                            isActive: root.step === 5
                        }

                        SetupReadyStep {
                            theme: root.theme
                            font: root.font
                            selectedPreset: root.selectedPreset
                            detectedTools: root.detectedTools
                            detectedHardware: root.detectedHardware
                            scriptPath: root.scriptPath
                            onRefreshToolsRequested: root.refreshToolsRequested()
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Skip setup"
                    font.family: root.font
                    font.pixelSize: 12
                    color: skipMouse.containsMouse ? root.theme.textPrimary : root.theme.textMuted
                    scale: skipMouse.pressed ? 0.96 : (skipMouse.containsMouse ? 1.02 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: skipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeWith(() => root.skipRequested())
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: root.step > 0 || (root.step === 0 && presetStep.customizingBar)
                    radius: 8
                    color: backBtnMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                    border.color: backBtnMouse.containsMouse
                        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55)
                        : root.theme.bgBorder
                    border.width: 1
                    implicitWidth: 84
                    implicitHeight: 34
                    scale: backBtnMouse.pressed ? 0.96 : (backBtnMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: backBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.step === 0 && presetStep.customizingBar) {
                                presetStep.customizingBar = false;
                            } else if (root.step === 1 && themeStep.subView !== "main") {
                                themeStep.subView = "main";
                            } else if (root.step === 4 && shortcutsStep.customizingShortcuts) {
                                shortcutsStep.customizingShortcuts = false;
                            } else {
                                root.step = Math.max(0, root.step - 1);
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Back"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                    }
                }

                Rectangle {
                    radius: 8
                    color: nextBtnMouse.containsMouse ? Qt.lighter(root.theme.accentPrimary, 1.12) : root.theme.accentPrimary
                    implicitWidth: 96
                    implicitHeight: 34
                    scale: nextBtnMouse.pressed ? 0.96 : (nextBtnMouse.containsMouse ? 1.03 : 1.0)
                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: nextBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.step < root.stepTitles.length - 1) {
                                root.step++;
                            } else {
                                root.closeWith(() => root.finishRequested());
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.step < root.stepTitles.length - 1 ? "Next" : "Finish"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.bgBase
                    }
                }
            }
        }
    }
}
