import QtQuick
import QtQuick.Layouts
import "../Common"

ColumnLayout {
    id: outputSection
    required property var root

    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Output"
        font.family: outputSection.root.font
        font.pixelSize: Style.px(13)
        font.bold: true
        color: outputSection.root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: outputCol.implicitHeight + 16
        radius: 12
        color: outputSection.root.theme.bgSurface
        border.color: outputSection.root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: outputCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Output Device Selector */
            Item {
                Layout.fillWidth: true
                implicitHeight: 52
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Output Device"
                            font.family: outputSection.root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: outputSection.root.theme.textPrimary
                        }

                        Text {
                            text: outputSection.root.defaultSink
                                ? (outputSection.root.defaultSink.description || outputSection.root.defaultSink.name || "Default Output")
                                : "No output device available"
                            font.family: outputSection.root.font
                            font.pixelSize: Style.px(11)
                            color: outputSection.root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        id: sinkChangeBtn
                        implicitWidth: outputSection.root.actionBtnWidth
                        implicitHeight: outputSection.root.btnHeight
                        Layout.preferredWidth: outputSection.root.actionBtnWidth
                        Layout.preferredHeight: outputSection.root.btnHeight
                        width: outputSection.root.actionBtnWidth
                        height: outputSection.root.btnHeight
                        radius: outputSection.root.btnRadius
                        color: outputSection.root.outputDropdownOpen
                            ? outputSection.root.theme.bgSelected
                            : (sinkChangeHover.hovered ? outputSection.root.theme.bgHover : outputSection.root.theme.bgBase)
                        border.color: outputSection.root.outputDropdownOpen
                            ? outputSection.root.theme.accentPrimary
                            : (sinkChangeHover.hovered ? Qt.rgba(outputSection.root.theme.accentPrimary.r, outputSection.root.theme.accentPrimary.g, outputSection.root.theme.accentPrimary.b, 0.4) : outputSection.root.theme.bgBorder)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: sinkChangeHover }

                        Text {
                            anchors.centerIn: parent
                            text: outputSection.root.outputDropdownOpen ? "Done" : "Change"
                            font.family: outputSection.root.font
                            font.pixelSize: Style.px(12)
                            font.bold: true
                            color: outputSection.root.outputDropdownOpen ? outputSection.root.theme.accentPrimary : outputSection.root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!outputSection.root.outputDropdownOpen) outputSection.root.inputDropdownOpen = false;
                                outputSection.root.outputDropdownOpen = !outputSection.root.outputDropdownOpen;
                            }
                        }
                    }
                }
            }

            /* Expandable Output Devices List */
            SoundExpandableOutputDevicesList {
                root: outputSection.root
            }

            RowDivider {}

            /* Row 2: Master Volume Slider & Mute Toggle */
            SoundMasterVolumeRow {
                id: soundRow2MasterVolumeInst
                root: outputSection.root
            }

            RowDivider {}

            /* Row 3: Stereo Balance Slider */
            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        Layout.preferredWidth: outputSection.root.labelColWidth
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: "Balance"
                            font.family: outputSection.root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: outputSection.root.theme.textPrimary
                        }

                        Text {
                            text: Math.abs(outputSection.root.balance) < 0.04
                                ? "Balanced"
                                : (outputSection.root.balance < 0 ? ("Left " + Math.round(-outputSection.root.balance * 100) + "%") : ("Right " + Math.round(outputSection.root.balance * 100) + "%"))
                            font.family: outputSection.root.font
                            font.pixelSize: Style.px(11)
                            font.bold: true
                            color: Math.abs(outputSection.root.balance) < 0.04 ? outputSection.root.theme.textSecondary : outputSection.root.theme.accentPrimary
                        }
                    }

                    Rectangle {
                        id: balTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        implicitHeight: 6
                        height: 6
                        radius: 3
                        color: outputSection.root.theme.bgSelected
                        border.color: outputSection.root.theme.bgBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: 2
                            height: 12
                            radius: 1
                            color: Qt.rgba(1, 1, 1, 0.25)
                        }

                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            property real normPos: (outputSection.root.balance + 1.0) / 2.0
                            x: outputSection.root.balance < 0 ? (balTrack.width * normPos) : (balTrack.width * 0.5)
                            width: Math.abs((balTrack.width * normPos) - (balTrack.width * 0.5))
                            color: outputSection.root.theme.accentPrimary
                        }

                        Rectangle {
                            anchors.centerIn: balKnob
                            width: balKnob.width + (balMouse.pressed ? 8 : (balMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(outputSection.root.theme.accentPrimary.r, outputSection.root.theme.accentPrimary.g, outputSection.root.theme.accentPrimary.b, balMouse.pressed ? 0.35 : (balMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Rectangle {
                            id: balKnob
                            width: balMouse.containsMouse || balMouse.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: outputSection.root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(balTrack.width - width, (balTrack.width * ((outputSection.root.balance + 1.0) / 2.0)) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                enabled: !balMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: balMouse
                            anchors.fill: parent
                            anchors.topMargin: -8
                            anchors.bottomMargin: -8
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                outputSection.root.isDraggingBalance = true;
                                outputSection.root.balanceDragBaseVol = (outputSection.root.currentSinkMasterVolume > 0.001)
                                    ? outputSection.root.currentSinkMasterVolume
                                    : (outputSection.root.defaultSink && outputSection.root.defaultSink.audio && outputSection.root.defaultSink.audio.volume > 0.001 ? outputSection.root.defaultSink.audio.volume : 0.5);
                                updateBalanceFromPos(mouse.x);
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    mouse.accepted = true;
                                    updateBalanceFromPos(mouse.x);
                                }
                            }
                            onReleased: {
                                outputSection.root.isDraggingBalance = false;
                            }
                            onCanceled: {
                                outputSection.root.isDraggingBalance = false;
                            }
                            function updateBalanceFromPos(mouseX) {
                                if (balTrack.width > 0) {
                                    const frac = Math.max(0, Math.min(1.0, mouseX / balTrack.width));
                                    let bal = (frac * 2.0) - 1.0;
                                    if (Math.abs(bal) < 0.05) bal = 0.0;
                                    outputSection.root.setBalance(bal);
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: outputSection.root.actionBtnWidth
                        implicitHeight: outputSection.root.btnHeight
                        Layout.preferredWidth: outputSection.root.actionBtnWidth
                        Layout.preferredHeight: outputSection.root.btnHeight
                        width: outputSection.root.actionBtnWidth
                        height: outputSection.root.btnHeight
                        radius: outputSection.root.btnRadius
                        color: centerHover.hovered ? outputSection.root.theme.bgHover : outputSection.root.theme.bgBase
                        border.color: centerHover.hovered ? outputSection.root.theme.accentPrimary : outputSection.root.theme.bgBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: centerHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Center"
                            font.family: outputSection.root.font
                            font.pixelSize: Style.px(12)
                            font.bold: true
                            color: outputSection.root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: outputSection.root.setBalance(0.0)
                        }
                    }
                }
            }

            RowDivider {}

            /* Row 4: Stereo Speaker Channel Test */
            SoundChannelTestRow {
                root: outputSection.root
            }
        }
    }
}
