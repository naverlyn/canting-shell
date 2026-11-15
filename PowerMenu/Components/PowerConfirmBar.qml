import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var theme
    required property string font
    required property var pendingAction
    required property color pendingAccent
    required property int secondsLeft

    signal cancelRequested()
    signal confirmRequested()

    readonly property bool confirming: root.pendingAction !== null && root.pendingAction !== undefined
    property bool ready: false

    Component.onCompleted: Qt.callLater(() => { root.ready = true; })

    visible: height > 0
    clip: true
    opacity: root.confirming ? 1.0 : 0.0
    Layout.fillWidth: true
    Layout.preferredHeight: root.confirming ? 52 : 0

    Behavior on Layout.preferredHeight {
        enabled: root.ready
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        enabled: root.ready
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        clip: true
        color: Qt.rgba(root.pendingAccent.r, root.pendingAccent.g, root.pendingAccent.b, 0.14)
        border.width: 1
        border.color: root.pendingAccent

        // Subtle countdown progress bar along the bottom edge
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            height: 2
            width: root.confirming ? parent.width * Math.max(0, Math.min(1, root.secondsLeft / 5.0)) : 0
            color: root.pendingAccent
            Behavior on width {
                enabled: root.confirming
                NumberAnimation { duration: 950; easing.type: Easing.Linear }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: root.confirming
                    ? (root.pendingAction.label + " in " + root.secondsLeft + "s...")
                    : ""
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
                elide: Text.ElideRight
            }

            Rectangle {
                implicitWidth: cancelLbl.implicitWidth + 20
                implicitHeight: 32
                radius: 8
                color: cancelMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.width: 1
                border.color: root.theme.bgBorder

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
                    onClicked: root.cancelRequested()
                }
            }

            Rectangle {
                implicitWidth: confirmLbl.implicitWidth + 20
                implicitHeight: 32
                radius: 8
                color: confirmMouse.containsMouse ? Qt.lighter(root.pendingAccent, 1.1) : root.pendingAccent

                Text {
                    id: confirmLbl
                    anchors.centerIn: parent
                    text: "Confirm (Enter)"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.bgBase
                }

                MouseArea {
                    id: confirmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.confirmRequested()
                }
            }
        }
    }
}
