import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

// ---------------------------------------------------------
SectionCard {
    required property var root
    title: "Curated Typography Pairings"
    subtitle: "Click any pairing to apply it across Quickshell"

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        Repeater {
            model: root.curatedPairings
            delegate: Rectangle {
                id: pairCard
                required property var modelData
                required property int index

                readonly property string resolvedUi: root.resolveAvailableFont(modelData.uiCandidates, modelData.uiFallback)
                readonly property string resolvedMono: root.resolveAvailableFont(modelData.monoCandidates, modelData.monoFallback)
                readonly property bool isCurrentPair: root.theme.savedFontFamily === resolvedUi && root.theme.savedMonoFont === resolvedMono

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: pairCardCol.implicitHeight + 20
                radius: 10
                color: isCurrentPair
                    ? Style.withAlpha(root.theme.accentPrimary, 0.13)
                    : (pairMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                border.color: isCurrentPair
                    ? root.theme.accentPrimary
                    : (pairMouse.containsMouse ? Style.withAlpha(root.theme.accentPrimary, 0.45) : root.theme.bgBorder)
                border.width: isCurrentPair ? 1.5 : 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                ColumnLayout {
                    id: pairCardCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 10
                    }
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: modelData.name
                            font.family: pairCard.resolvedUi
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            height: 16
                            radius: 4
                            implicitWidth: pairBadgeTxt.implicitWidth + 10
                            color: pairCard.isCurrentPair
                                ? root.theme.accentPrimary
                                : Style.withAlpha(root.theme.accentPrimary, 0.14)

                            Text {
                                id: pairBadgeTxt
                                anchors.centerIn: parent
                                text: pairCard.isCurrentPair ? "ACTIVE" : modelData.badge
                                font.family: Style.font
                                font.pixelSize: 9
                                font.bold: true
                                color: pairCard.isCurrentPair ? root.theme.bgBase : root.theme.accentPrimary
                            }
                        }
                    }

                    Text {
                        text: modelData.desc
                        font.family: Style.font
                        font.pixelSize: Style.px(10)
                        color: root.theme.textSecondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            height: 20
                            radius: 5
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            Text {
                                id: uiChipTxt
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                text: "UI: " + pairCard.resolvedUi
                                font.family: pairCard.resolvedUi
                                font.pixelSize: 10
                                color: root.theme.textPrimary
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            height: 20
                            radius: 5
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            Text {
                                id: monoChipTxt
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                text: "Mono: " + pairCard.resolvedMono
                                font.family: pairCard.resolvedMono
                                font.pixelSize: 10
                                color: root.theme.accentCyan
                            }
                        }
                    }
                }

                MouseArea {
                    id: pairMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.theme.setFontPairing(pairCard.resolvedUi, pairCard.resolvedMono);
                        root.showToast("Applied '" + modelData.name + "' font pairing");
                    }
                }
            }
        }
    }
}
