import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: studioPreviewCard
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 45
    radius: 8
    color: root.theme.bgBase
    border.color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 1
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // Sandbox Header with Mode Switcher & Replay
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Motion Sandbox"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textPrimary
            }

            Item { Layout.fillWidth: true }

            // Mode Switcher (Strictly text-only)
            RowLayout {
                spacing: 4
                Repeater {
                    model: [
                        { id: "windowsIn", label: "Window Open" },
                        { id: "windowsOut", label: "Window Close" },
                        { id: "layersIn", label: "Layer / Popup" },
                        { id: "workspaces", label: "Workspace" }
                    ]

                    Rectangle {
                        id: sModePill
                        property var sModeItem: modelData
                        height: 26
                        implicitWidth: sModeText.implicitWidth + 16
                        radius: 6
                        color: root.previewMode === sModeItem.id
                            ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                            : (sModeHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.05)) : root.theme.bgBase)
                        border.color: root.previewMode === sModeItem.id
                            ? root.theme.accentPrimary
                            : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: sModeHover }

                        Text {
                            id: sModeText
                            anchors.centerIn: parent
                            text: sModePill.sModeItem.label
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: root.previewMode === sModePill.sModeItem.id
                            color: root.previewMode === sModePill.sModeItem.id ? root.theme.accentPrimary : root.theme.textSecondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.previewMode = sModePill.sModeItem.id;
                                root.triggerPreview();
                            }
                        }
                    }
                }
            }

            // Replay button
            Rectangle {
                height: 26
                implicitWidth: replayText.implicitWidth + 18
                radius: 6
                color: replayHover.hovered ? Qt.darker(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary
                Behavior on color { ColorAnimation { duration: 140 } }

                HoverHandler { id: replayHover }

                Text {
                    id: replayText
                    anchors.centerIn: parent
                    text: "Replay"
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: true
                    color: "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.triggerPreview()
                }
            }
        }

        // Interactive Simulated Stage
        Rectangle {
            id: previewStage
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.22)
            clip: true
            border.color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1

            // 1. WINDOW OPEN / CLOSE SIMULATION
            Rectangle {
                id: studioMockWindow
                visible: root.previewMode === "windowsIn" || root.previewMode === "windowsOut"
                width: 150
                height: 72
                radius: 6
                anchors.centerIn: parent
                color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)
                border.color: root.theme.accentPrimary
                border.width: 1.5

                readonly property real effectiveP: root.previewMode === "windowsOut" ? (1.0 - root.animProgress) : root.animProgress

                scale: {
                    if (root.currentPreviewStyle.indexOf("popin 60%") !== -1) {
                        return Math.max(0.1, 0.6 + effectiveP * 0.4);
                    } else if (root.currentPreviewStyle.indexOf("popin") !== -1) {
                        return Math.max(0.1, 0.8 + effectiveP * 0.2);
                    } else if (root.currentPreviewStyle.indexOf("gnomed") !== -1) {
                        return Math.max(0.1, 0.88 + effectiveP * 0.12);
                    }
                    return 1.0;
                }

                opacity: Math.max(0.0, Math.min(1.0, effectiveP * 1.5))

                transform: Translate {
                    y: {
                        if (root.currentPreviewStyle.indexOf("slide") !== -1) {
                            return (1.0 - studioMockWindow.effectiveP) * 50;
                        }
                        return 0;
                    }
                }

                // Window Header Bar
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 18
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.06)

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Rectangle { width: 5; height: 5; radius: 2.5; color: "#f7768e" }
                        Rectangle { width: 5; height: 5; radius: 2.5; color: "#e0af68" }
                        Rectangle { width: 5; height: 5; radius: 2.5; color: "#9ece6a" }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.newAnimName || "Window"
                        font.family: root.font
                        font.pixelSize: 8
                        color: root.theme.textSecondary
                        elide: Text.ElideRight
                        width: 80
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Window Body Text
                ColumnLayout {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 6
                    spacing: 2

                    Text {
                        text: root.previewMode === "windowsIn" ? "WINDOW OPENING" : "WINDOW CLOSING"
                        font.family: root.font
                        font.pixelSize: 9
                        font.bold: true
                        color: root.theme.accentPrimary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Curve: " + root.currentPreviewCurveName + " • " + root.currentPreviewStyle
                        font.family: root.font
                        font.pixelSize: 8
                        color: root.theme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // 2. LAYER / POPUP SIMULATION
            Item {
                id: layerSimulationArea
                visible: root.previewMode === "layersIn"
                anchors.fill: parent

                // Mock Panel Bar at Top
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 18
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Text { text: "Panel / Waybar"; font.family: root.font; font.pixelSize: 8; color: root.theme.textMuted }
                    }
                }

                // Mock Popup Card Dropping Down
                Rectangle {
                    width: 140
                    height: 60
                    radius: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                    border.color: root.theme.accentPrimary
                    border.width: 1.5

                    y: {
                        if (root.currentPreviewStyle.indexOf("popin") !== -1) {
                            return 26;
                        }
                        return 8 + root.animProgress * 18;
                    }

                    scale: root.currentPreviewStyle.indexOf("popin") !== -1
                        ? Math.max(0.1, 0.8 + root.animProgress * 0.2)
                        : 1.0

                    opacity: Math.max(0.0, Math.min(1.0, root.animProgress * 1.5))

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: "POPUP / LAUNCHER"
                            font.family: root.font
                            font.pixelSize: 9
                            font.bold: true
                            color: root.theme.accentPrimary
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "layersIn • " + root.currentPreviewStyle
                            font.family: root.font
                            font.pixelSize: 8
                            color: root.theme.textSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            // 3. WORKSPACE TRANSITION SIMULATION
            Item {
                id: workspaceSimulationArea
                visible: root.previewMode === "workspaces"
                anchors.fill: parent

                readonly property bool isVert: root.currentPreviewStyle.indexOf("vert") !== -1
                readonly property real p: root.animProgress

                // Workspace 1 (Exiting)
                Rectangle {
                    width: 110
                    height: 60
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    x: workspaceSimulationArea.isVert
                        ? (parent.width - width) / 2
                        : ((parent.width - width) / 2 - workspaceSimulationArea.p * (parent.width * 0.55))

                    y: workspaceSimulationArea.isVert
                        ? ((parent.height - height) / 2 - workspaceSimulationArea.p * (parent.height * 0.65))
                        : ((parent.height - height) / 2)

                    opacity: Math.max(0.0, 1.0 - workspaceSimulationArea.p)

                    Text {
                        anchors.centerIn: parent
                        text: "WS 1 (Old)"
                        font.family: root.font
                        font.pixelSize: 9
                        color: root.theme.textMuted
                    }
                }

                // Workspace 2 (Entering)
                Rectangle {
                    width: 110
                    height: 60
                    radius: 6
                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)
                    border.color: root.theme.accentPrimary
                    border.width: 1.5

                    x: workspaceSimulationArea.isVert
                        ? (parent.width - width) / 2
                        : ((parent.width - width) / 2 + (1.0 - workspaceSimulationArea.p) * (parent.width * 0.55))

                    y: workspaceSimulationArea.isVert
                        ? ((parent.height - height) / 2 + (1.0 - workspaceSimulationArea.p) * (parent.height * 0.65))
                        : ((parent.height - height) / 2)

                    opacity: Math.max(0.0, Math.min(1.0, workspaceSimulationArea.p * 1.5))

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: "WS 2 (Active)"
                            font.family: root.font
                            font.pixelSize: 9
                            font.bold: true
                            color: root.theme.accentPrimary
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: root.currentPreviewStyle
                            font.family: root.font
                            font.pixelSize: 8
                            color: root.theme.textSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        // Sandbox Information Badges
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Target: " + root.previewMode
                font.family: root.font
                font.pixelSize: 9
                color: root.theme.textSecondary
            }

            Text {
                text: "• Curve: " + root.currentPreviewCurveName
                font.family: root.font
                font.pixelSize: 9
                color: root.theme.accentPrimary
            }

            Text {
                text: "• Speed: " + root.currentPreviewSpeed + " (" + (root.currentPreviewSpeed * 100) + "ms)"
                font.family: root.font
                font.pixelSize: 9
                color: root.theme.textSecondary
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Style: " + (root.currentPreviewStyle || "default")
                font.family: root.font
                font.pixelSize: 9
                font.bold: true
                color: root.theme.textPrimary
            }
        }
    }
}
