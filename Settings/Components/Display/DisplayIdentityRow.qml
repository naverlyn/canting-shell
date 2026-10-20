import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../MonitorManager"
import "../../../MonitorManager/Components"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    Layout.fillWidth: true
    height: 54

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            RowLayout {
                spacing: 8

                Text {
                    text: root.selectedMonitor ? root.selectedMonitor.name : ""
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Rectangle {
                    height: 18
                    implicitWidth: statusTag.implicitWidth + 10
                    radius: 5
                    color: (root.selectedMonitor && !root.selectedMonitor.disabled)
                        ? Qt.rgba((root.theme.accentGreen ?? root.theme.accentPrimary).r,
                                  (root.theme.accentGreen ?? root.theme.accentPrimary).g,
                                  (root.theme.accentGreen ?? root.theme.accentPrimary).b, 0.15)
                        : Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        id: statusTag
                        anchors.centerIn: parent
                        text: (root.selectedMonitor && !root.selectedMonitor.disabled)
                            ? (root.editState.length === 1 ? "Primary Output" : "Enabled")
                            : "Disabled"
                        font.family: root.font
                        font.pixelSize: 10
                        font.bold: true
                        color: (root.selectedMonitor && !root.selectedMonitor.disabled)
                            ? (root.theme.accentGreen ?? root.theme.accentPrimary)
                            : root.theme.textMuted
                    }
                }
            }

            Text {
                text: {
                    if (!root.selectedMonitor) return "";
                    const desc = root.selectedMonitor.description || "Connected Display Output";
                    const lw = Math.round(MonitorUtils.logicalW(root.selectedMonitor));
                    const lh = Math.round(MonitorUtils.logicalH(root.selectedMonitor));
                    return desc + "  ·  Logical " + lw + " × " + lh;
                }
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        /* Enable/Disable Switch (shown when >1 monitor or when monitor is disabled) */
        Rectangle {
            visible: root.editState.length > 1 || (root.selectedMonitor && root.selectedMonitor.disabled)
            width: 44
            height: 24
            radius: 12
            readonly property bool isMonEnabled: root.selectedMonitor ? !root.selectedMonitor.disabled : true
            color: isMonEnabled ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 160 } }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                x: parent.isMonEnabled ? parent.width - width - 3 : 3
                color: parent.isMonEnabled ? "#ffffff" : root.theme.textPrimary

                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleSelectedMonitorEnabled()
            }
        }
    }
}
