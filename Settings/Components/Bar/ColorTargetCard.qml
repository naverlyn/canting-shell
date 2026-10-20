import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "1. Select Building Block or Panel to Color"
    subtitle: "Pick any block or panel below, then choose a color"

    Rectangle {
        Layout.fillWidth: true
        height: 44
        radius: 9
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: "Targets:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
            }

            Rectangle {
                id: barTargetBtn
                readonly property bool isTarget: root.selectedColorTargetType === "bar"
                readonly property string barSpec: BarConfig.currentBar ? (BarConfig.currentBar.barColor || "") : (BarConfig.barColor || "")
                readonly property color barCol: root.resolveThemeSpec(barSpec, root.theme.bgBase)

                implicitWidth: barTargetRow.implicitWidth + 20
                implicitHeight: 28
                width: implicitWidth
                height: implicitHeight
                radius: 6
                scale: barTargetMouse.pressed ? 0.94 : (barTargetHover.hovered ? 1.04 : 1.0)
                color: isTarget
                    ? root.theme.bgSelected
                    : (barTargetHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
                border.color: isTarget ? root.theme.accentPrimary : (barTargetHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder)
                border.width: isTarget ? 1.5 : 1

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: barTargetHover }

                RowLayout {
                    id: barTargetRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 2
                        color: barTargetBtn.barCol
                        border.color: root.theme.bgBorder
                        border.width: 1
                    }

                    Text {
                        text: "Bar Background"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: barTargetBtn.isTarget
                        color: barTargetBtn.isTarget ? root.theme.accentPrimary : root.theme.textPrimary
                    }
                }

                MouseArea {
                    id: barTargetMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedColorTargetType = "bar";
                    }
                }
            }

            Rectangle {
                width: 1
                height: 18
                color: root.theme.bgBorder
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "Panels:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
            }

            Repeater {
                model: BarConfig.panels
                delegate: Rectangle {
                    id: panelTargetBtn
                    required property var modelData
                    required property int index
                    readonly property bool isTarget: root.selectedColorTargetType === "panel" && root.selectedColorPanelIndex === index
                    readonly property string pSpec: root.getPanelColorSpec(index)
                    readonly property color pCol: root.resolveThemeSpec(pSpec, root.theme.accentPrimary)

                    implicitWidth: panelTargetTxt.implicitWidth + 18
                    implicitHeight: 28
                    width: implicitWidth
                    height: implicitHeight
                    radius: 6
                    scale: panelTargetMouse.pressed ? 0.94 : (pTargetHover.hovered ? 1.04 : 1.0)
                    color: isTarget
                        ? root.theme.bgSelected
                        : (pTargetHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
                    border.color: isTarget ? pCol : (pTargetHover.hovered ? root.withAlpha(pCol, 0.45) : root.theme.bgBorder)
                    border.width: isTarget ? 1.5 : 1

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: pTargetHover }

                    Text {
                        id: panelTargetTxt
                        anchors.centerIn: parent
                        text: BarConfig.getPanelTitle(panelTargetBtn.index)
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: panelTargetBtn.isTarget
                        color: panelTargetBtn.isTarget ? panelTargetBtn.pCol : root.theme.textPrimary
                    }

                    MouseArea {
                        id: panelTargetMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedColorTargetType = "panel";
                            root.selectedColorPanelIndex = panelTargetBtn.index;
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            ActionButton {
                iconText: "󰦛"
                label: "Reset Block Colors"
                danger: true
                btnHeight: 28
                onClicked: root.clearAllBlockColorsForCurrentBar()
            }
        }
    }

    GridLayout {
        columns: 3
        columnSpacing: 10
        rowSpacing: 10
        Layout.fillWidth: true

        Repeater {
            model: BarConfig.widgetDefinitions
            delegate: Rectangle {
                id: colorBlockCard
                required property var modelData
                readonly property bool isSelectedTarget: root.selectedColorTargetType === "block" && root.selectedColorWidgetId === modelData.id
                readonly property string spec: root.getBlockColorSpec(modelData.id)
                readonly property bool hasCustom: spec !== ""
                readonly property color resolvedCol: root.resolveThemeSpec(spec, root.theme.accentPrimary)
                readonly property string panelBadge: root.getWidgetPanelBadge(modelData.id)

                Layout.fillWidth: true
                implicitHeight: 44
                height: 44
                radius: 8
                color: isSelectedTarget
                    ? root.theme.bgSelected
                    : (cbHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                border.color: isSelectedTarget
                    ? resolvedCol
                    : (hasCustom ? root.withAlpha(resolvedCol, 0.5) : root.theme.bgBorder)
                border.width: isSelectedTarget ? 1.5 : 1

                Behavior on color { ColorAnimation { duration: 130 } }
                Behavior on border.color { ColorAnimation { duration: 130 } }

                HoverHandler { id: cbHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: colorBlockCard.modelData.icon
                        font.family: root.font
                        font.pixelSize: 14
                        color: colorBlockCard.resolvedCol
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: colorBlockCard.modelData.name
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: colorBlockCard.panelBadge + " · " + root.getSpecLabel(colorBlockCard.spec)
                            font.family: root.font
                            font.pixelSize: 9
                            color: colorBlockCard.hasCustom ? colorBlockCard.resolvedCol : root.theme.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                MouseArea {
                    id: cbMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedColorTargetType = "block";
                        root.selectedColorWidgetId = colorBlockCard.modelData.id;
                    }
                }
            }
        }
    }
}
