import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

                Rectangle {
                    id: sidebarRect
    required property var hostApp
    required property var hostWindow
    required property var winCard
                    Layout.fillHeight: true
                    Layout.preferredWidth: winCard.sidebarWidth
                    width: winCard.sidebarWidth
                    color: hostApp.theme.bgSurface
                    radius: 12
                    
                    // Square off right corners adjacent to main content
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 12
                        color: parent.color
                    }

                    // Subtle vertical border dividing sidebar and content
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: hostApp.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    }

                    // Interactive horizontal splitter to resize sidebar
                    MouseArea {
                        id: sidebarSplitter
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -4
                        width: 9
                        cursorShape: Qt.SplitHCursor
                        z: 20

                        property real startScreenX: 0
                        property int startW: 0

                        onPressed: (mouse) => {
                            let pt = mapToItem(hostWindow, mouse.x, 0);
                            startScreenX = pt.x;
                            startW = winCard.sidebarWidth;
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                let curPt = mapToItem(hostWindow, mouse.x, 0);
                                let delta = curPt.x - startScreenX;
                                winCard.sidebarWidth = Math.max(190, Math.min(360, startW + delta));
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 14
                        anchors.bottomMargin: 14
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        // Sidebar Header with Drag Handle indicator
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            Layout.bottomMargin: 2

                            Text {
                                text: "Settings"
                                font.family: hostApp.font
                                font.pixelSize: 18
                                font.bold: true
                                color: hostApp.theme.textPrimary
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                text: "󰓅"
                                font.family: hostApp.font
                                font.pixelSize: 13
                                color: hostApp.theme.textMuted
                                Layout.alignment: Qt.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Scrollable categorized sections
                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: sectionsCol.implicitHeight
                            contentWidth: width
                            flickableDirection: Flickable.VerticalFlick
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle {
                                    implicitWidth: 3
                                    radius: 2
                                    color: hostApp.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
                                }
                            }

                            ColumnLayout {
                                id: sectionsCol
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: hostWindow.visible ? hostApp.sections : []
                                    delegate: ColumnLayout {
                                        id: secCol
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        spacing: 1

                                        // Section Category Header
                                        Item {
                                            Layout.fillWidth: true
                                            height: secCol.index === 0 ? 18 : 22

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 3
                                                text: secCol.modelData.category
                                                font.family: hostApp.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                font.capitalization: Font.AllUppercase
                                                color: hostApp.theme.textMuted ?? Qt.rgba(1,1,1,0.4)
                                            }
                                        }

                                        // Section Items
                                        Repeater {
                                            model: secCol.modelData.items
                                            delegate: Rectangle {
                                                id: itemRect
                                                required property var modelData
                                                required property int index

                                                Layout.fillWidth: true
                                                height: 33
                                                radius: 7
                                                color: hostApp.currentTab === itemRect.modelData.pageIndex
                                                    ? hostApp.theme.bgSelected
                                                    : (tabMouse.containsMouse ? (hostApp.theme.bgHover ?? Qt.rgba(1,1,1,0.05)) : "transparent")

                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 12
                                                    spacing: 10

                                                    Item {
                                                        width: 18
                                                        height: 18
                                                        Layout.alignment: Qt.AlignVCenter

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: itemRect.modelData.icon
                                                            font.family: hostApp.font
                                                            font.pixelSize: 14
                                                            color: hostApp.currentTab === itemRect.modelData.pageIndex
                                                                ? hostApp.theme.accentPrimary
                                                                : hostApp.theme.textSecondary
                                                            horizontalAlignment: Text.AlignHCenter
                                                            verticalAlignment: Text.AlignVCenter
                                                            Behavior on color { ColorAnimation { duration: 150 } }
                                                        }
                                                    }

                                                    Text {
                                                        text: itemRect.modelData.name
                                                        font.family: hostApp.font
                                                        font.pixelSize: 13
                                                        font.bold: hostApp.currentTab === itemRect.modelData.pageIndex
                                                        color: hostApp.currentTab === itemRect.modelData.pageIndex
                                                            ? hostApp.theme.textPrimary
                                                            : hostApp.theme.textSecondary
                                                        Layout.fillWidth: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                        elide: Text.ElideRight
                                                        Behavior on color { ColorAnimation { duration: 150 } }
                                                    }
                                                }

                                                MouseArea {
                                                    id: tabMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: hostApp.currentTab = itemRect.modelData.pageIndex
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
