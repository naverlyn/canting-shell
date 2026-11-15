import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: overviewWindow

    required property var theme
    required property string font
    required property string mode
    required property var toplevels
    required property var workspaces
    required property int selectedIndex
    required property string searchQuery

    signal modeChangedByUser(string nextMode)
    signal searchQueryChangedByUser(string query)
    signal selectionChanged(int index)
    signal windowFocused(var toplevel)
    signal windowClosed(var toplevel)
    signal workspaceSwitched(int wsId)
    signal closeRequested()

    visible: true
    focusable: true
    color: "transparent"

    property bool ready: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell:overview"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            overviewWindow.ready = true;
            if (overviewWindow.mode === "workspaces") {
                workspaceView.focusSearch();
            } else {
                keyHandler.forceActiveFocus();
            }
        });
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
            overviewWindow.closeRequested();
            event.accepted = true;
            return;
        }

        if (overviewWindow.mode !== "switcher") return;
        const count = overviewWindow.toplevels.length;
        if (count === 0) return;

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            overviewWindow.windowFocused(overviewWindow.toplevels[overviewWindow.selectedIndex]);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Delete) {
            overviewWindow.windowClosed(overviewWindow.toplevels[overviewWindow.selectedIndex]);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            overviewWindow.selectionChanged((overviewWindow.selectedIndex + 1) % count);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
            overviewWindow.selectionChanged((overviewWindow.selectedIndex + count - 1) % count);
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            const cols = Math.min(4, count);
            const delta = (event.key === Qt.Key_Down) ? cols : -cols;
            overviewWindow.selectionChanged((overviewWindow.selectedIndex + delta + count) % count);
            event.accepted = true;
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
                onClicked: overviewWindow.closeRequested()
            }
        }

        FocusScope {
            id: keyHandler
            anchors.fill: parent
            focus: true
            Keys.onPressed: (event) => overviewWindow.handleKeyPress(event)

            Rectangle {
                id: card
                anchors.centerIn: parent
                readonly property real targetW: overviewWindow.mode === "workspaces"
                    ? 980
                    : switcherView.implicitWidth + 48
                width: overviewWindow.width > 0
                    ? Math.min(targetW, overviewWindow.width - 48)
                    : targetW
                height: cardCol.implicitHeight + 44
                radius: 20
                clip: true
                color: overviewWindow.theme.bgBase
                border.width: 1
                border.color: overviewWindow.theme.bgBorder

                Behavior on width {
                    enabled: overviewWindow.ready
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                Behavior on height {
                    enabled: overviewWindow.ready
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: cardCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 22
                    }
                    spacing: 16

                    // Header + Mode Switcher
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: overviewWindow.mode === "workspaces" ? "Workspace Overview" : "Window Switcher"
                            font.family: overviewWindow.font
                            font.pixelSize: 16
                            font.bold: true
                            color: overviewWindow.theme.textPrimary
                        }

                        Item { Layout.fillWidth: true }

                        // Mode Toggle Pill
                        Rectangle {
                            implicitWidth: modeRow.implicitWidth + 8
                            implicitHeight: 32
                            radius: 10
                            color: overviewWindow.theme.bgSurface
                            border.width: 1
                            border.color: overviewWindow.theme.bgBorder

                            RowLayout {
                                id: modeRow
                                anchors.centerIn: parent
                                spacing: 4

                                Repeater {
                                    model: [
                                        { id: "switcher", label: "Switcher" },
                                        { id: "workspaces", label: "Workspaces" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool active: overviewWindow.mode === modelData.id

                                        implicitWidth: modeLbl.implicitWidth + 18
                                        implicitHeight: 24
                                        radius: 7
                                        color: active ? overviewWindow.theme.accentPrimary : "transparent"

                                        Text {
                                            id: modeLbl
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: overviewWindow.font
                                            font.pixelSize: 12
                                            font.bold: active
                                            color: active ? overviewWindow.theme.bgBase : overviewWindow.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                overviewWindow.modeChangedByUser(modelData.id);
                                                if (modelData.id === "workspaces") {
                                                    Qt.callLater(() => workspaceView.focusSearch());
                                                } else {
                                                    Qt.callLater(() => keyHandler.forceActiveFocus());
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: closeMouse.containsMouse ? overviewWindow.theme.bgHover : overviewWindow.theme.bgSurface
                            border.width: 1
                            border.color: overviewWindow.theme.bgBorder

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.family: overviewWindow.font
                                font.pixelSize: 13
                                color: overviewWindow.theme.textSecondary
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: overviewWindow.closeRequested()
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: overviewWindow.mode === "workspaces"
                            ? workspaceView.implicitHeight
                            : switcherView.implicitHeight

                        SwitcherView {
                            id: switcherView
                            anchors.fill: parent
                            opacity: overviewWindow.mode === "switcher" ? 1.0 : 0.0
                            visible: opacity > 0.01
                            Behavior on opacity {
                                enabled: overviewWindow.ready
                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                            }
                            theme: overviewWindow.theme
                            font: overviewWindow.font
                            toplevels: overviewWindow.toplevels
                            selectedIndex: overviewWindow.selectedIndex
                            onSelectionChanged: (idx) => overviewWindow.selectionChanged(idx)
                            onWindowClicked: (t) => overviewWindow.windowFocused(t)
                            onWindowClosed: (t) => overviewWindow.windowClosed(t)
                        }

                        WorkspaceGridView {
                            id: workspaceView
                            anchors.fill: parent
                            opacity: overviewWindow.mode === "workspaces" ? 1.0 : 0.0
                            visible: opacity > 0.01
                            Behavior on opacity {
                                enabled: overviewWindow.ready
                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                            }
                            theme: overviewWindow.theme
                            font: overviewWindow.font
                            workspaces: overviewWindow.workspaces
                            toplevels: overviewWindow.toplevels
                            searchQuery: overviewWindow.searchQuery
                            onSearchQueryChangedByUser: (q) => overviewWindow.searchQueryChangedByUser(q)
                            onWindowClicked: (t) => overviewWindow.windowFocused(t)
                            onWindowClosed: (t) => overviewWindow.windowClosed(t)
                            onWorkspaceClicked: (wsId) => overviewWindow.workspaceSwitched(wsId)
                        }
                    }
                }
            }
        }
    }
}
