import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../bar"

RowLayout {
    id: root

    property var theme
    property string font: "Hack Nerd Font"
    property string userName: "User"

    signal closeRequested()

    width: parent ? parent.width : 300
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

    function openWlogout() {
        root.closeRequested();
        wlogoutProc.running = true;
    }

    function openSettings() {
        root.closeRequested();
        qsSettingsProc.running = true;
    }

    // User Profile Section
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            width: 30; height: 30; radius: 15
            color: root.theme ? root.theme.accentPrimary : "#a6e3a1"
            
            Text {
                anchors.centerIn: parent
                text: ""
                font.family: root.font
                font.pixelSize: 14
                color: root.theme ? root.theme.bgBase : "#1e1e2e"
            }
        }

        Text {
            text: root.userName
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme ? root.theme.textPrimary : "#cdd6f4"
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    // Battery Info Pill
    Rectangle {
        width: 76
        height: 30
        radius: 15
        color: root.theme ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) : Qt.rgba(1, 1, 1, 0.08)

        Row {
            anchors.centerIn: parent
            spacing: 6
            
            Text {
                text: SystemInfo.batteryIcon ? SystemInfo.batteryIcon : "󰁹"
                font.family: root.font
                font.pixelSize: 13
                color: root.theme ? root.theme.textPrimary : "#cdd6f4"
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: SystemInfo.batteryLevel ? SystemInfo.batteryLevel : "AC"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme ? root.theme.textPrimary : "#cdd6f4"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Circular Settings Button
    Rectangle {
        width: 30; height: 30; radius: 15
        color: root.theme ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) : Qt.rgba(1, 1, 1, 0.08)

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: root.font
            font.pixelSize: 13
            color: root.theme ? root.theme.textPrimary : "#cdd6f4"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openSettings()
        }
    }

    // Circular Power Button
    Rectangle {
        width: 30; height: 30; radius: 15
        color: root.theme ? root.theme.accentPrimary : "#a6e3a1"

        Text {
            anchors.centerIn: parent
            text: "󰐥"
            font.family: root.font
            font.pixelSize: 13
            color: root.theme ? root.theme.bgBase : "#1e1e2e"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openWlogout()
        }
    }
}
