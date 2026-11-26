import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

ColumnLayout {
    id: expanderRow
    required property var theme
    required property string font
    property string title: ""
    property string currentValue: ""
    property var options: []
    property bool isOpen: false
    signal toggleRequested()
    signal optionSelected(string desktopFile, var optionData)

    function getDisplayName(optionsList, desktopFile) {
        if (!desktopFile) return "Select application...";
        const found = optionsList.find(o => o.desktop.toLowerCase() === desktopFile.toLowerCase());
        return found ? found.name : desktopFile;
    }

    Layout.fillWidth: true
    spacing: 0

    Item {
        Layout.fillWidth: true
        height: 50

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Text {
                text: expanderRow.title
                font.family: expanderRow.font
                font.pixelSize: Style.px(13)
                font.bold: true
                color: expanderRow.theme.textPrimary
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: appDropdownBtn
                Layout.preferredWidth: 240
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: 7
                color: appPopup.visible
                    ? expanderRow.theme.bgSelected
                    : (pillHover.hovered ? expanderRow.theme.bgHover : expanderRow.theme.bgBase)
                border.color: appPopup.visible
                    ? expanderRow.theme.accentPrimary
                    : (pillHover.hovered
                        ? Qt.rgba(expanderRow.theme.accentPrimary.r, expanderRow.theme.accentPrimary.g, expanderRow.theme.accentPrimary.b, 0.5)
                        : expanderRow.theme.bgBorder)
                border.width: appPopup.visible ? 1.5 : 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: pillHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: expanderRow.getDisplayName(expanderRow.options, expanderRow.currentValue)
                        font.family: expanderRow.font
                        font.pixelSize: Style.px(12)
                        font.bold: true
                        color: expanderRow.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "󰅀"
                        font.family: expanderRow.font
                        font.pixelSize: Style.px(13)
                        color: appPopup.visible ? expanderRow.theme.accentPrimary : expanderRow.theme.textSecondary
                        rotation: appPopup.visible ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (appPopup.visible) appPopup.close();
                        else expanderRow.toggleRequested();
                    }
                }

                Popup {
                    id: appPopup
                    y: appDropdownBtn.height + 4
                    width: appDropdownBtn.width
                    padding: 4
                    modal: false
                    focus: true
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                    transformOrigin: Item.Top

                    Connections {
                        target: expanderRow
                        function onIsOpenChanged() {
                            if (expanderRow.isOpen && !appPopup.visible) appPopup.open();
                            else if (!expanderRow.isOpen && appPopup.visible) appPopup.close();
                        }
                    }

                    onVisibleChanged: {
                        if (!visible && expanderRow.isOpen) {
                            expanderRow.toggleRequested();
                        }
                    }

                    enter: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                            NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                        }
                    }

                    exit: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 110; easing.type: Easing.InCubic }
                            NumberAnimation { property: "scale"; from: 1.0; to: 0.96; duration: 110; easing.type: Easing.InCubic }
                        }
                    }

                    background: Rectangle {
                        radius: 8
                        color: expanderRow.theme.bgSurface
                        border.color: expanderRow.theme.bgBorder
                        border.width: 1
                    }

                    contentItem: ColumnLayout {
                        spacing: 2

                        Repeater {
                            model: expanderRow.options
                            delegate: Rectangle {
                                id: appOptItem
                                required property var modelData
                                readonly property bool isSelected: expanderRow.currentValue.toLowerCase() === modelData.desktop.toLowerCase()
                                Layout.fillWidth: true
                                height: 30
                                radius: 6
                                color: isSelected
                                    ? expanderRow.theme.bgSelected
                                    : (itemHover.hovered ? expanderRow.theme.bgHover : "transparent")
                                Behavior on color { ColorAnimation { duration: 110 } }

                                HoverHandler { id: itemHover }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: appOptItem.modelData.name
                                        font.family: expanderRow.font
                                        font.pixelSize: Style.px(12)
                                        font.bold: appOptItem.isSelected
                                        color: appOptItem.isSelected ? expanderRow.theme.accentPrimary : expanderRow.theme.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        expanderRow.optionSelected(appOptItem.modelData.desktop, appOptItem.modelData);
                                        appPopup.close();
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
