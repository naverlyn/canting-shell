import Quickshell
import Quickshell.Widgets
import QtQuick
import ".."
import "../../utils/AppFrecencyUtils.js" as AppFrecencyUtils

Item {
    id: root

    required property var theme
    required property string font
    required property var appsModel
    required property var appUsage
    required property int selectedIndex
    required property string searchQuery

    readonly property alias count: resultsList.count

    signal appSelected(int index)
    signal appLaunched(var entry)

    function scrollToIndex(idx, mode) {
        if (resultsList.count > 0 && idx >= 0 && idx < resultsList.count) {
            resultsList.positionViewAtIndex(idx, mode !== undefined ? mode : ListView.Contain);
        }
    }

    ListView {
        id: resultsList
        anchors.fill: parent
        model: root.appsModel
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.selectedIndex
        highlightMoveDuration: 150
        highlightMoveVelocity: -1

        highlight: Rectangle {
            radius: 8
            color: root.theme.bgSelected
            visible: resultsList.count > 0 && root.selectedIndex >= 0
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                width: 3
                height: 24
                radius: 2
                color: root.theme.accentPrimary
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        delegate: Rectangle {
            id: delegateRoot
            required property var modelData
            required property int index
            readonly property string appKey: AppFrecencyUtils.getAppKey(modelData)
            readonly property int launchCount: (appKey && root.appUsage[appKey]) ? (root.appUsage[appKey].count || 0) : 0
            readonly property bool isFav: AppLauncherConfig.isAppFavorite(appKey)
            readonly property string subTitle: delegateRoot.modelData.genericName ?? delegateRoot.modelData.comment ?? ""

            Accessible.role: Accessible.Button
            Accessible.name: (modelData.name ?? "Application") + (delegateRoot.subTitle ? " - " + delegateRoot.subTitle : "")

            width: resultsList.width
            height: 44
            radius: 8
            color: hoverArea.containsMouse && root.selectedIndex !== index ? root.theme.bgHover : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            Item {
                id: iconContainer
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 24
                    source: Quickshell.iconPath(delegateRoot.modelData.icon ?? "", true)
                    visible: (delegateRoot.modelData.icon ?? "") !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰀻"
                    color: root.theme.accentPrimary
                    font.pixelSize: 16
                    font.family: root.font
                    visible: (delegateRoot.modelData.icon ?? "") === ""
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Row {
                id: rightIndicators
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    visible: delegateRoot.launchCount > 0
                    text: "󰋚"
                    color: root.selectedIndex === delegateRoot.index ? root.theme.accentPrimary : root.theme.textMuted
                    font.pixelSize: 12
                    font.family: root.font
                    opacity: 0.75
                }
            }

            Item {
                anchors.left: iconContainer.right
                anchors.leftMargin: 12
                anchors.right: rightIndicators.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: delegateRoot.subTitle !== "" ? 34 : 20

                Row {
                    anchors.left: parent.left
                    anchors.top: delegateRoot.subTitle !== "" ? parent.top : undefined
                    anchors.verticalCenter: delegateRoot.subTitle === "" ? parent.verticalCenter : undefined
                    spacing: 6

                    Text {
                        text: delegateRoot.modelData.name ?? ""
                        color: root.selectedIndex === delegateRoot.index ? root.theme.textPrimary : root.theme.textSecondary
                        font.pixelSize: 13
                        font.family: root.font
                        font.bold: root.selectedIndex === delegateRoot.index
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        visible: delegateRoot.isFav
                        text: "󰓎"
                        font.family: root.font
                        font.pixelSize: 10
                        color: "#e5c07b"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    visible: delegateRoot.subTitle !== ""
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: delegateRoot.subTitle
                    color: root.theme.textMuted
                    font.pixelSize: 11
                    font.family: root.font
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.appLaunched(delegateRoot.modelData)
                onEntered: root.appSelected(delegateRoot.index)
            }
        }

        Text {
            anchors.centerIn: parent
            text: "No applications found"
            color: root.theme.textMuted
            font.pixelSize: 13
            font.family: root.font
            visible: resultsList.count === 0 && root.searchQuery !== ""
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}
