import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../osd"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Volume Levels"
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textSecondary
            Layout.leftMargin: 4
        }

        Item { Layout.fillWidth: true }

        Text {
            text: root.appStreams.length > 0 ? (root.appStreams.length + (root.appStreams.length === 1 ? " application" : " applications")) : "No active streams"
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textSecondary
            Layout.rightMargin: 4
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: streamCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        Column {
            id: streamCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Empty State when no apps are streaming */
            Item {
                visible: root.appStreams.length === 0
                width: parent.width
                height: visible ? 64 : 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "No applications currently playing audio"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Streams will appear here automatically when apps produce sound"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            /* Active Audio Streams Repeater */
            Repeater {
                model: root.appStreams
                delegate: Item {
                    width: streamCol.width > 0 ? streamCol.width : (parent ? parent.width : 0)
                    height: 53

                    readonly property var streamNode: modelData
                    readonly property bool isStreamMuted: !streamNode || !streamNode.audio || streamNode.audio.muted
                    readonly property int streamVolPct: (streamNode && streamNode.audio) ? Math.round(streamNode.audio.volume * 100) : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 16

                        ColumnLayout {
                            Layout.preferredWidth: root.labelColWidth
                            Layout.minimumWidth: root.labelColWidth
                            Layout.maximumWidth: root.labelColWidth
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                text: root.getStreamAppName(streamNode)
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: isStreamMuted ? "Muted" : (streamVolPct + "%")
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: isStreamMuted ? (root.theme.accentRed ?? "#f7768e") : (root.theme.accentPrimary ?? "#7aa2f7")
                            }
                        }

                        /* App Slider Track */
                        Rectangle {
                            id: appTrack
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            implicitHeight: 6
                            height: 6
                            radius: 3
                            color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            Layout.alignment: Qt.AlignVCenter

                            // Active progress fill bar
                            Rectangle {
                                id: appFillBar
                                height: parent.height
                                radius: parent.radius
                                width: Math.max(0, Math.min(parent.width, parent.width * (streamVolPct / 100)))
                                color: isStreamMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                            }

                            // Outer halo ring
                            Rectangle {
                                anchors.centerIn: appKnob
                                width: appKnob.width + (appMouse.pressed ? 8 : (appMouse.containsMouse ? 6 : 0))
                                height: width
                                radius: width / 2
                                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, appMouse.pressed ? 0.35 : (appMouse.containsMouse ? 0.2 : 0))
                                z: 1

                                Behavior on width { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            // Tactile white knob
                            Rectangle {
                                id: appKnob
                                width: appMouse.containsMouse || appMouse.pressed ? 17 : 15
                                height: width
                                radius: width / 2
                                color: "#ffffff"
                                border.color: isStreamMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                                border.width: 3
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(appTrack.width - width, (appTrack.width * (streamVolPct / 100)) - (width / 2)))
                                z: 2

                                Behavior on width { NumberAnimation { duration: 120 } }
                                Behavior on x {
                                    enabled: !appMouse.pressed
                                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                }
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                anchors.topMargin: -8
                                anchors.bottomMargin: -8
                                preventStealing: true
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => {
                                    mouse.accepted = true;
                                    if (streamNode && streamNode.audio && appTrack.width > 0) {
                                        const frac = Math.max(0, Math.min(1.0, mouse.x / appTrack.width));
                                        streamNode.audio.volume = frac;
                                    }
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed && streamNode && streamNode.audio && appTrack.width > 0) {
                                        mouse.accepted = true;
                                        const frac = Math.max(0, Math.min(1.0, mouse.x / appTrack.width));
                                        streamNode.audio.volume = frac;
                                    }
                                }
                            }
                        }

                        /* Standardized App Mute Pill Button */
                        Rectangle {
                            implicitWidth: root.actionBtnWidth
                            implicitHeight: root.btnHeight
                            Layout.preferredWidth: root.actionBtnWidth
                            Layout.preferredHeight: root.btnHeight
                            width: root.actionBtnWidth
                            height: root.btnHeight
                            radius: root.btnRadius
                            color: isStreamMuted 
                                ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) 
                                : (appMuteHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
                            border.color: isStreamMuted 
                                ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.4) 
                                : (appMuteHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                            border.width: 1
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: appMuteHover }

                            Text {
                                anchors.centerIn: parent
                                text: isStreamMuted ? "Muted" : "Mute"
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: isStreamMuted ? root.theme.accentRed : root.theme.textPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (streamNode && streamNode.audio) {
                                        streamNode.audio.muted = !streamNode.audio.muted;
                                    }
                                }
                            }
                        }
                    }

                    /* Row Divider between streams */
                    Rectangle {
                        visible: index < root.appStreams.length - 1
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.05)
                    }
                }
            }
        }
    }
}
