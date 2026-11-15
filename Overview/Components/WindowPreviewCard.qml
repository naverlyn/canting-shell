import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var theme
    required property string font
    required property var toplevel
    required property bool isSelected
    property bool compact: false

    signal clicked()
    signal closeClicked()
    signal hovered()

    readonly property string appClass: (toplevel && toplevel.lastIpcObject && (toplevel.lastIpcObject.class || toplevel.lastIpcObject.initialClass)) || ""
    readonly property string windowTitle: (toplevel && toplevel.title) ? toplevel.title : (appClass !== "" ? appClass : "Window")
    readonly property int wsId: (toplevel && toplevel.workspace) ? toplevel.workspace.id : -1
    readonly property bool isFocused: Boolean(toplevel && toplevel.activated)
    readonly property var desktopEntry: appClass !== "" ? DesktopEntries.heuristicLookup(appClass) : null
    readonly property string iconSource: (desktopEntry && desktopEntry.icon) ? Quickshell.iconPath(desktopEntry.icon, true) : ""

    implicitWidth: compact ? 210 : 250
    implicitHeight: compact ? 156 : 186
    radius: 14
    color: root.isSelected
        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.14)
        : (cardMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
    border.width: root.isSelected ? 2 : 1
    border.color: root.isSelected
        ? root.theme.accentPrimary
        : (root.isFocused ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.5) : root.theme.bgBorder)

    scale: cardMouse.pressed ? 0.97 : 1.0
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onEntered: root.hovered()
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                root.closeClicked();
            } else {
                root.clicked();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Live Window Thumbnail Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 9
            color: root.theme.bgBase
            border.width: 1
            border.color: root.theme.bgBorder
            clip: true

            ScreencopyView {
                id: preview
                anchors.fill: parent
                captureSource: (root.toplevel && root.toplevel.wayland) ? root.toplevel.wayland : null
                live: true
                paintCursor: false
                constraintSize: Qt.size(Math.max(1, width), Math.max(1, height))
                visible: hasContent
            }

            // Fallback when no screencopy frame is available yet
            Item {
                anchors.fill: parent
                visible: !preview.hasContent

                IconImage {
                    anchors.centerIn: parent
                    width: 40
                    height: 40
                    source: root.iconSource
                    visible: root.iconSource !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.iconSource === ""
                    text: "󰖯"
                    font.family: root.font
                    font.pixelSize: 28
                    color: root.theme.textMuted
                }
            }

            // Workspace badge (top-left)
            Rectangle {
                visible: root.wsId > 0
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 6
                implicitWidth: wsLbl.implicitWidth + 12
                implicitHeight: 20
                radius: 6
                color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.85)
                border.width: 1
                border.color: root.theme.bgBorder

                Text {
                    id: wsLbl
                    anchors.centerIn: parent
                    text: "WS " + root.wsId
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: true
                    color: root.isFocused ? root.theme.accentPrimary : root.theme.textSecondary
                }
            }

            // Close window button (top-right on hover/select)
            Rectangle {
                visible: cardMouse.containsMouse || closeMouse.containsMouse || root.isSelected
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                width: 22
                height: 22
                radius: 11
                color: closeMouse.containsMouse
                    ? root.theme.accentRed
                    : Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, 0.85)
                border.width: 1
                border.color: closeMouse.containsMouse ? root.theme.accentRed : root.theme.bgBorder
                z: 2

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: root.font
                    font.pixelSize: 10
                    color: closeMouse.containsMouse ? root.theme.bgBase : root.theme.textSecondary
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeClicked()
                }
            }
        }

        // Bottom Title & Icon Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            IconImage {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                source: root.iconSource
                visible: root.iconSource !== ""
            }

            Text {
                Layout.fillWidth: true
                text: root.windowTitle
                font.family: root.font
                font.pixelSize: 12
                font.bold: root.isSelected || root.isFocused
                color: root.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
}
