import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../bar"
import ".."

RowLayout {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"
    property string userName: "User"

    signal closeRequested()

    width: parent ? parent.width : 300
    implicitHeight: 30
    Layout.preferredHeight: 30
    spacing: 12

    // Fetch the current username
    Process {
        command: ["whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    const name = text.trim();
                    root.userName = name.charAt(0).toUpperCase() + name.slice(1);
                }
            }
        }
    }

    // wlogout Process
    Process {
        id: wlogoutProc
        command: ["sh", "-c", "pidof wlogout || wlogout"]
        running: false
    }

    // Quickshell Settings Process
    Process {
        id: qsSettingsProc
        command: ["qs", "ipc", "call", "settings", "toggle"]
        running: false
    }

    // Quickshell Control Center Settings Process (opens directly to tab 17)
    Process {
        id: qsCcSettingsProc
        command: ["qs", "ipc", "call", "settings", "open", "controlcenter"]
        running: false
    }

    function openWlogout() {
        root.closeRequested();
        wlogoutProc.running = true;
    }

    function openSettings() {
        root.closeRequested();
        qsSettingsProc.running = true;
    }

    function openControlCenterSettings() {
        root.closeRequested();
        qsCcSettingsProc.running = true;
    }

    // User Profile Section
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            width: 30; height: 30; radius: 15
            color: root.theme.accentPrimary
            
            Text {
                anchors.centerIn: parent
                text: ""
                font.family: root.font
                font.pixelSize: 14
                color: root.theme.bgBase
            }
        }

        Text {
            text: root.userName
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textPrimary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    // Battery Info Pill
    Rectangle {
        width: 76
        height: 30
        radius: 15
        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08)

        Row {
            anchors.centerIn: parent
            spacing: 6
            
            Text {
                text: SystemInfo.batteryIcon ? SystemInfo.batteryIcon : "󰁹"
                font.family: root.font
                font.pixelSize: 13
                color: root.theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: SystemInfo.batteryLevel ? SystemInfo.batteryLevel : "AC"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Circular Edit Tiles (Pencil) Button
    Rectangle {
        id: editTilesBtn
        width: 30; height: 30; radius: 15
        color: ControlCenterConfig.isLiveEdit
            ? root.theme.accentPrimary
            : (editTilesMouse.containsMouse
                ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
                : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06))
        scale: editTilesMouse.pressed ? 0.94 : 1.0
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: "󰏫"
            font.family: root.font
            font.pixelSize: 13
            color: ControlCenterConfig.isLiveEdit ? root.theme.bgBase : root.theme.textPrimary
        }

        MouseArea {
            id: editTilesMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    root.openControlCenterSettings();
                } else {
                    ControlCenterConfig.isLiveEdit = !ControlCenterConfig.isLiveEdit;
                }
            }
        }
    }

    // Circular Settings Button
    Rectangle {
        id: settingsBtn
        width: 30; height: 30; radius: 15
        color: settingsMouse.containsMouse
            ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
            : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
        scale: settingsMouse.pressed ? 0.94 : 1.0
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: ""
            font.family: root.font
            font.pixelSize: 13
            color: root.theme.textPrimary
        }

        MouseArea {
            id: settingsMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openSettings()
        }
    }

    // Circular Power Button
    Rectangle {
        id: powerBtn
        width: 30; height: 30; radius: 15
        color: powerMouse.containsMouse
            ? Qt.lighter(root.theme.accentPrimary, 1.12)
            : root.theme.accentPrimary
        scale: powerMouse.pressed ? 0.94 : 1.0
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

        Text {
            anchors.centerIn: parent
            text: "󰐥"
            font.family: root.font
            font.pixelSize: 13
            color: root.theme.bgBase
        }

        MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openWlogout()
        }
    }
}
