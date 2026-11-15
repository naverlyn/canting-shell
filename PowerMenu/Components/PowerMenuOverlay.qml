import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: powerWindow

    required property var theme
    required property string font
    required property var actions
    required property int selectedIndex
    required property int pendingActionIndex
    required property int confirmSecondsLeft
    required property string userName
    required property string uptimeText
    required property var accentResolver

    signal closeRequested()
    signal cancelConfirmRequested()
    signal actionTriggered(int index)
    signal actionConfirmed(int index)
    signal selectionChanged(int index)

    visible: true
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-powermenu"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Component.onCompleted: {
        Qt.callLater(() => keyHandler.forceActiveFocus());
        fadeInAnim.start();
    }

    NumberAnimation {
        id: fadeInAnim
        target: overlayRoot
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: 130
        easing.type: Easing.OutCubic
    }

    function handleKeyPress(event) {
        if (event.key === Qt.Key_Escape) {
            if (powerWindow.pendingActionIndex >= 0) {
                powerWindow.cancelConfirmRequested();
            } else {
                powerWindow.closeRequested();
            }
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (powerWindow.pendingActionIndex >= 0) {
                powerWindow.actionConfirmed(powerWindow.pendingActionIndex);
            } else {
                powerWindow.actionTriggered(powerWindow.selectedIndex);
            }
            event.accepted = true;
            return;
        }

        const count = powerWindow.actions.length;
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
            powerWindow.selectionChanged((powerWindow.selectedIndex + count - 1) % count);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            powerWindow.selectionChanged((powerWindow.selectedIndex + 1) % count);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            powerWindow.selectionChanged((powerWindow.selectedIndex + 3) % count);
            event.accepted = true;
            return;
        }

        const ch = (event.text || "").toUpperCase();
        if (ch.length === 1) {
            for (let i = 0; i < count; i++) {
                if (powerWindow.actions[i].hotkey === ch) {
                    powerWindow.actionTriggered(i);
                    event.accepted = true;
                    return;
                }
            }
        }
    }

    Item {
        id: overlayRoot
        anchors.fill: parent
        opacity: 0.0

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.56)

            MouseArea {
                anchors.fill: parent
                onClicked: powerWindow.closeRequested()
            }
        }

        FocusScope {
            id: keyHandler
            anchors.fill: parent
            focus: true
            Keys.onPressed: (event) => powerWindow.handleKeyPress(event)

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: powerWindow.width > 0 ? Math.min(540, powerWindow.width - 48) : 540
                height: cardCol.implicitHeight + 48
                radius: 20
                color: powerWindow.theme.bgBase
                border.width: 1
                border.color: powerWindow.theme.bgBorder

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

                    PowerMenuHeader {
                        theme: powerWindow.theme
                        font: powerWindow.font
                        userName: powerWindow.userName
                        uptimeText: powerWindow.uptimeText
                        onCloseRequested: powerWindow.closeRequested()
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 12
                        columnSpacing: 12

                        Repeater {
                            model: powerWindow.actions

                            delegate: PowerActionTile {
                                required property int index
                                required property var modelData

                                theme: powerWindow.theme
                                font: powerWindow.font
                                actionData: modelData
                                accent: powerWindow.accentResolver(modelData)
                                isSelected: powerWindow.selectedIndex === index
                                isPending: powerWindow.pendingActionIndex === index

                                onHovered: powerWindow.selectionChanged(index)
                                onTriggered: powerWindow.actionTriggered(index)
                            }
                        }
                    }

                    PowerConfirmBar {
                        readonly property var pendingAct: powerWindow.pendingActionIndex >= 0
                            ? powerWindow.actions[powerWindow.pendingActionIndex]
                            : null

                        theme: powerWindow.theme
                        font: powerWindow.font
                        pendingAction: pendingAct
                        pendingAccent: powerWindow.accentResolver(pendingAct)
                        secondsLeft: powerWindow.confirmSecondsLeft

                        onCancelRequested: powerWindow.cancelConfirmRequested()
                        onConfirmRequested: powerWindow.actionConfirmed(powerWindow.pendingActionIndex)
                    }
                }
            }
        }
    }
}
