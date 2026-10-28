import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../ControlCenter"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    Layout.fillWidth: true
    spacing: 20


    property alias panel1Card: p1Card
    property alias panel2Card: p2Card
    property alias panel3Card: p3Card
    property alias panel1Repeater: p1Card.repeater
    property alias panel2Repeater: p2Card.repeater
    property alias panel3Repeater: p3Card.repeater
    property alias poolCard: availPoolCard

    property alias groupPanel: groupPanelCard
    property alias standalonePanel: standalonePanelCard
    property alias secondaryPanel: secondaryPanelCard
    property alias groupRepeater: groupPanelCard.repeater
    property alias standaloneRepeater: standalonePanelCard.repeater
    property alias secondaryRepeater: secondaryPanelCard.repeater
    property alias tilesPoolCard: availTilesPoolCard

    visible: root.currentSubTab === 0

    // =========================================================================
    // CARD 1: 3-PANEL MODULAR BUILDING BLOCKS
    // =========================================================================
    SectionCard {
        title: "Control Center Panels & Building Blocks"
        subtitle: "Stack any combination of modules into Panel 1, Panel 2, and Panel 3 · MPRIS automatically switches to Compact when stacked with other modules"

        // Top Controls Bar (matches BarLayoutCard.qml)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: 9
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: "Active Panels:"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                }

                RowLayout {
                    spacing: 8

                    Repeater {
                        model: [1, 2, 3]
                        delegate: Rectangle {
                            id: pCountBtn
                            required property int modelData
                            readonly property bool isCurrent: ControlCenterConfig.panelCount === modelData
                            implicitWidth: pCountTxt.implicitWidth + 18
                            implicitHeight: 30
                            width: implicitWidth
                            height: implicitHeight
                            color: "transparent"
                            border.width: 0
                            scale: pCountMouse.pressed ? 0.94 : (pCountHover.hovered ? 1.04 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            HoverHandler { id: pCountHover }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 2
                                radius: 1
                                width: pCountBtn.isCurrent ? parent.width - 6 : (pCountHover.hovered ? parent.width * 0.5 : 0)
                                opacity: pCountBtn.isCurrent ? 1.0 : (pCountHover.hovered ? 0.5 : 0.0)
                                color: pCountBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            Text {
                                id: pCountTxt
                                anchors.centerIn: parent
                                text: pCountBtn.modelData + (pCountBtn.modelData === 1 ? " Panel" : " Panels")
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: pCountBtn.isCurrent
                                color: pCountBtn.isCurrent
                                    ? root.theme.accentPrimary
                                    : (pCountHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: pCountMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ControlCenterConfig.setPanelCount(pCountBtn.modelData);
                                    root.showToast("Control Center set to " + pCountBtn.modelData + (pCountBtn.modelData === 1 ? " Panel" : " Panels"));
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                ActionButton {
                    iconText: "󰎁"
                    label: "MPRIS: " + ControlCenterConfig.mediaEffectiveBadge
                    btnHeight: 28
                    onClicked: {
                        ControlCenterConfig.cycleMediaWidgetStyle();
                        root.showToast("Media Player mode: " + ControlCenterConfig.mediaEffectiveBadge);
                    }
                }

                ActionButton {
                    iconText: ControlCenterConfig.panelLayout === "horizontal" ? "󰝙" : "󰝘"
                    label: ControlCenterConfig.panelLayout === "horizontal" ? "Horizontal" : "Vertical"
                    btnHeight: 28
                    onClicked: {
                        const nextLayout = ControlCenterConfig.panelLayout === "horizontal" ? "vertical" : "horizontal";
                        ControlCenterConfig.setPanelLayout(nextLayout);
                        root.showToast("Flyout layout set to " + (nextLayout === "horizontal" ? "Horizontal" : "Vertical"));
                    }
                }
            }
        }

        // 3-Column Modular Panels Grid (Panel 1, Panel 2, Panel 3)
        GridLayout {
            id: blockBuilderLayout
            columns: 3
            columnSpacing: 12
            rowSpacing: 12
            Layout.fillWidth: true

            ControlCenterModulePanel {
                id: p1Card
                hostRoot: self.root
                panelIndex: 0
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            ControlCenterModulePanel {
                id: p2Card
                hostRoot: self.root
                panelIndex: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            ControlCenterModulePanel {
                id: p3Card
                hostRoot: self.root
                panelIndex: 2
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // Available Building-Block Modules Pool Card
        ControlCenterModulesPool {
            id: availPoolCard
            hostRoot: self.root
        }
    }

    // =========================================================================
    // CARD 2: QUICK SETTINGS & 2x2 CONNECTIVITY TILES
    // =========================================================================
    SectionCard {
        title: "Quick Settings & Connectivity Tiles"
        subtitle: "Configure which toggles appear in Connectivity (2x2), Quick Tiles, and Quick Tiles 2"

        GridLayout {
            columns: 3
            columnSpacing: 12
            rowSpacing: 12
            Layout.fillWidth: true
            ControlCenterConnectivityPanel {
                id: groupPanelCard
                hostRoot: self.root
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            ControlCenterQuickTilesPanel {
                id: standalonePanelCard
                hostRoot: self.root
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            ControlCenterQuickTiles2Panel {
                id: secondaryPanelCard
                hostRoot: self.root
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // Available Quick Tiles Pool Card
        ControlCenterTilesPool {
            id: availTilesPoolCard
            hostRoot: self.root
        }
    }
}
