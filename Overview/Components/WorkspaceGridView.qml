import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var theme
    required property string font
    required property var workspaces
    required property var toplevels
    required property string searchQuery

    signal searchQueryChangedByUser(string query)
    signal windowClicked(var toplevel)
    signal windowClosed(var toplevel)
    signal workspaceClicked(int wsId)

    function windowsForWorkspace(wsId) {
        const q = root.searchQuery.trim().toLowerCase();
        return root.toplevels.filter(t => {
            if (!t || !t.workspace || t.workspace.id !== wsId) return false;
            if (q === "") return true;
            const title = (t.title || "").toLowerCase();
            const cls = ((t.lastIpcObject && (t.lastIpcObject.class || t.lastIpcObject.initialClass)) || "").toLowerCase();
            return title.indexOf(q) !== -1 || cls.indexOf(q) !== -1;
        });
    }

    function focusSearch() {
        searchInput.forceActiveFocus();
    }

    implicitWidth: 960
    implicitHeight: Math.min(620, col.implicitHeight)

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 14

        // Filter Input Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 10
            color: root.theme.bgSurface
            border.width: searchInput.activeFocus ? 2 : 1
            border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "󰍉"
                    font.family: root.font
                    font.pixelSize: 14
                    color: root.theme.textMuted
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: root.theme.textPrimary
                    font.family: root.font
                    font.pixelSize: 13
                    clip: true
                    onTextChanged: root.searchQueryChangedByUser(text)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Filter windows by title or app..."
                        font.family: root.font
                        font.pixelSize: 13
                        color: root.theme.textMuted
                        visible: searchInput.text.length === 0
                    }
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Math.min(540, wsGrid.implicitHeight)
            contentHeight: wsGrid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            GridLayout {
                id: wsGrid
                width: parent.width
                columns: 2
                rowSpacing: 14
                columnSpacing: 14

                Repeater {
                    model: root.workspaces

                    delegate: Rectangle {
                        id: wsCard
                        required property var modelData
                        readonly property var wsWindows: root.windowsForWorkspace(modelData.id)
                        readonly property bool isActiveWs: Boolean(modelData.active)

                        Layout.fillWidth: true
                        implicitHeight: Math.max(196, wsCol.implicitHeight + 24)
                        radius: 14
                        color: root.theme.bgSurface
                        border.width: isActiveWs ? 2 : 1
                        border.color: isActiveWs ? root.theme.accentPrimary : root.theme.bgBorder

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.workspaceClicked(wsCard.modelData.id)
                        }

                        ColumnLayout {
                            id: wsCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 12
                            }
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Workspace " + (wsCard.modelData.name || wsCard.modelData.id)
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: wsCard.isActiveWs ? root.theme.accentPrimary : root.theme.textPrimary
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: wsCard.wsWindows.length + (wsCard.wsWindows.length === 1 ? " window" : " windows")
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                }
                            }

                            Text {
                                visible: wsCard.wsWindows.length === 0
                                Layout.fillWidth: true
                                Layout.topMargin: 36
                                horizontalAlignment: Text.AlignHCenter
                                text: root.searchQuery.trim() !== "" ? "No matching windows" : "Empty workspace — click to switch"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textMuted
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                visible: wsCard.wsWindows.length > 0
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 10

                                Repeater {
                                    model: wsCard.wsWindows

                                    delegate: WindowPreviewCard {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        compact: true
                                        theme: root.theme
                                        font: root.font
                                        toplevel: modelData
                                        isSelected: false
                                        onClicked: root.windowClicked(modelData)
                                        onCloseClicked: root.windowClosed(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
