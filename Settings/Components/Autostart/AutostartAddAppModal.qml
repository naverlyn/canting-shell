import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../Common"

Rectangle {
    required property var root
    id: addAppModal
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.65)
    visible: root.addAppModalOpen
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea {
        anchors.fill: parent
        onClicked: root.addAppModalOpen = false
    }

    Rectangle {
        width: 500
        height: 520
        radius: 12
        color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : "#1e1e2e"
        border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        anchors.centerIn: parent

        MouseArea {
            anchors.fill: parent
            // absorb clicks inside modal dialog
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Modal Header
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Add Application to Autostart"
                        font.family: root.font
                        font.pixelSize: 16
                        font.bold: true
                        color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                    }

                    Text {
                        text: "Choose an installed desktop application to launch on login"
                        font.family: root.font
                        font.pixelSize: 11
                        color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeAddHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.1)) : "transparent"

                    HoverHandler { id: closeAddHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addAppModalOpen = false
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: root.font
                        font.pixelSize: 12
                        color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                    }
                }
            }

            // Search box
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 7
                color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                border.color: addSearchInput.activeFocus
                    ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                    : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: root.font
                        font.pixelSize: 13
                        color: addSearchInput.activeFocus
                            ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                            : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060")
                    }

                    TextInput {
                        id: addSearchInput
                        Layout.fillWidth: true
                        font.family: root.font
                        font.pixelSize: 12
                        color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                        clip: true
                        selectByMouse: true
                        text: root.addAppQuery
                        onTextChanged: root.addAppQuery = text

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !parent.text && !parent.activeFocus
                            text: "Search applications..."
                            font.family: root.font
                            font.pixelSize: 12
                            color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                        }
                    }
                }
            }

            // Applications List View Box
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.25)
                border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                clip: true

                ListView {
                    id: modalAppList
                    anchors.fill: parent
                    anchors.margins: 6
                    model: root.filteredAvailableApps
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.15)
                        }
                    }

                    delegate: Rectangle {
                        id: mAppRow
                        required property var modelData

                        width: modalAppList.width - 8
                        height: 48
                        radius: 6
                        color: mAppHover.hovered ? ((root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.08)) : "transparent"

                        HoverHandler { id: mAppHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const app = mAppRow.modelData;
                                root.addApp(app.name || "App", app.exec || "", app.icon || "", app.comment || "");
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            // App Icon
                            Rectangle {
                                id: mIconBox
                                width: 30
                                height: 30
                                radius: 6
                                color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.2)
                                border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1

                                readonly property string resIcon: {
                                    const raw = (mAppRow.modelData && mAppRow.modelData.icon) ? mAppRow.modelData.icon : "";
                                    if (raw) {
                                        const p = Quickshell.iconPath(raw, true);
                                        if (p) return p;
                                    }
                                    return Quickshell.iconPath("application-x-executable", true);
                                }

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 20
                                    source: mIconBox.resIcon
                                    visible: mIconBox.resIcon !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰵆"
                                    font.family: root.font
                                    font.pixelSize: 14
                                    color: (root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7"
                                    visible: mIconBox.resIcon === ""
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: mAppRow.modelData.name || "Unknown App"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: mAppRow.modelData.comment || mAppRow.modelData.exec || ""
                                    font.family: root.font
                                    font.pixelSize: 10
                                    color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070"
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: "󰐕 Add"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: mAppHover.hovered
                                    ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                    : ((root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0")
                            }
                        }
                    }
                }
            }
        }
    }
}
