import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../wallpaper"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Clock & Date Formatting"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: clockCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: clockCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            // Clock Time Format Row (Segmented track with sliding pill)
            PreferenceRow {
                title: "Time Format"
                subtitle: "12-Hour AM/PM or 24-Hour standard format"

                Rectangle {
                    id: timeFormatTrack
                    readonly property var modes: [
                        { id: "12h", label: "12-Hour" },
                        { id: "24h", label: "24-Hour" }
                    ]
                    readonly property int activeIdx: root.clockFormat === "24h" ? 1 : 0
                    readonly property int count: 2
                    readonly property real cellWidth: (width - 6 - 3) / 2
                    width: 220
                    height: 32
                    radius: 7
                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    /* Sliding Selection Pill */
                    Rectangle {
                        y: 3
                        height: parent.height - 6
                        width: timeFormatTrack.cellWidth
                        x: 3 + timeFormatTrack.activeIdx * (timeFormatTrack.cellWidth + 3)
                        radius: 5
                        color: root.theme.bgSelected
                        border.color: root.theme.accentPrimary ?? "#7aa2f7"
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        Repeater {
                            model: timeFormatTrack.modes
                            delegate: Rectangle {
                                id: tfBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: timeFormatTrack.activeIdx === tfBtn.index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && tfHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: tfHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: tfBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: tfBtn.isSel
                                    color: tfBtn.isSel ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.clockFormat = tfBtn.modelData.id;
                                        root.scheduleSave();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Clock Font Size
            PreferenceSlider {
                title: "Clock Font Size"
                subtitle: "Typography scale of the central time indicator"
                minVal: 60
                maxVal: 160
                unit: "pt"
                currentVal: root.clockFontSize
                onValueChanged: (val) => {
                    root.clockFontSize = val;
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Show Date Toggle
            PreferenceRow {
                title: "Show Date"
                subtitle: "Display weekday and calendar day beneath time"

                SwitchToggle {
                    checked: root.showDate
                    onToggled: (st) => {
                        root.showDate = st;
                        root.scheduleSave();
                    }
                }
            }
        }
    }
}
