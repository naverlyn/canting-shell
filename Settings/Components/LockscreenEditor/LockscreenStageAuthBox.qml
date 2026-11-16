import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Lockscreen"

Item {
    id: simAuthBox
    required property var hostStage
    required property var hostCanvas
    required property var hostGuides
    visible: !simAuthBox.hostStage.hasAuthModule
    readonly property real sFactor: simAuthBox.hostCanvas.scaleFactor
    readonly property bool isInputSelected: simAuthBox.hostStage.selectedIndex === -2
    readonly property color resolvedOuter: simAuthBox.hostStage.resolveColor(simAuthBox.hostStage.inputOuterColor)
    readonly property color resolvedInner: simAuthBox.hostStage.resolveColor(simAuthBox.hostStage.inputInnerColor)
    readonly property color resolvedFont: simAuthBox.hostStage.resolveColor(simAuthBox.hostStage.inputFontColor)

    readonly property real avatarSize: Math.round(104 * sFactor)
    readonly property real simInputW: Math.max(100, Math.round(simAuthBox.hostStage.inputWidth * sFactor))
    readonly property real simInputH: Math.max(22, Math.round(simAuthBox.hostStage.inputHeight * sFactor))

    width: Math.max(simInputW, avatarSize)
    height: authCol.implicitHeight
    z: isInputSelected || inputDragArea.drag.active ? 15 : 3
    scale: simAuthBox.hostStage.animAuthScale
    opacity: simAuthBox.hostStage.animModsOpacity
    transform: Translate { y: simAuthBox.hostStage.animAuthOffsetY }

    readonly property real targetX: {
        const curX = Number(simAuthBox.hostStage.liveInputX) || 0;
        if (simAuthBox.hostStage.inputHalign === "left") {
            return curX * sFactor;
        } else if (simAuthBox.hostStage.inputHalign === "right") {
            return simAuthBox.hostCanvas.width - width + (curX * sFactor);
        } else {
            return (simAuthBox.hostCanvas.width - width) / 2 + (curX * sFactor);
        }
    }

    readonly property real targetY: {
        const curY = Number(simAuthBox.hostStage.liveInputY) || 0;
        if (simAuthBox.hostStage.inputValign === "top") {
            return -(curY * sFactor);
        } else if (simAuthBox.hostStage.inputValign === "bottom") {
            return simAuthBox.hostCanvas.height - height - (curY * sFactor);
        } else {
            return (simAuthBox.hostCanvas.height - height) / 2 - (curY * sFactor);
        }
    }

    Binding on x {
        when: !inputDragArea.drag.active
        value: Math.max(2, Math.min(simAuthBox.hostCanvas.width - simAuthBox.width - 2, Math.round(simAuthBox.targetX)))
    }

    Binding on y {
        when: !inputDragArea.drag.active
        value: Math.max(2, Math.min(simAuthBox.hostCanvas.height - simAuthBox.height - 2, Math.round(simAuthBox.targetY)))
    }

    HoverHandler { id: inputBoxHover }

    ColumnLayout {
        id: authCol
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Math.max(4, Math.round(14 * simAuthBox.sFactor))

        // Avatar Circle
        Item {
            visible: simAuthBox.hostStage.showUser
            Layout.alignment: Qt.AlignHCenter
            width: simAuthBox.avatarSize
            height: simAuthBox.avatarSize

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: simAuthBox.hostStage.theme.accentGreen
                scale: simAuthBox.hostStage.animRippleScale
                opacity: simAuthBox.hostStage.animRippleOpacity
                visible: opacity > 0
            }

            Rectangle {
                id: avatarCircleBg
                anchors.fill: parent
                radius: width / 2
                color: simAuthBox.resolvedInner
                border.width: Math.max(1.5, Math.round(3 * simAuthBox.sFactor))
                border.color: (simAuthBox.isInputSelected || inputDragArea.drag.active)
                    ? simAuthBox.hostStage.theme.accentPrimary
                    : simAuthBox.resolvedOuter

                Image {
                    id: stageFaceImg
                    anchors.fill: parent
                    anchors.margins: 2
                    source: LockscreenConfig.faceIconPath !== "" ? ("file://" + LockscreenConfig.faceIconPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: stageFaceImg.status !== Image.Ready
                    text: "󰀉"
                    font.family: simAuthBox.hostStage.font
                    font.pixelSize: Math.round(44 * simAuthBox.sFactor)
                    color: simAuthBox.resolvedOuter
                }
            }
        }

        // Username Text
        Text {
            visible: simAuthBox.hostStage.showUser
            Layout.alignment: Qt.AlignHCenter
            text: simAuthBox.hostStage.username
            font.family: simAuthBox.hostStage.font
            font.pixelSize: Math.max(9, Math.round(18 * simAuthBox.sFactor))
            font.bold: true
            color: simAuthBox.hostStage.resolveColor("$text")
            style: Text.Outline
            styleColor: simAuthBox.hostStage.theme.bgOverlay
        }

        // Password Box
        Rectangle {
            id: inputPill
            Layout.alignment: Qt.AlignHCenter
            width: simAuthBox.simInputW
            height: simAuthBox.simInputH
            radius: Math.round(14 * simAuthBox.sFactor)
            color: Qt.rgba(simAuthBox.resolvedInner.r, simAuthBox.resolvedInner.g, simAuthBox.resolvedInner.b, 0.82)
            border.color: (simAuthBox.isInputSelected || inputDragArea.drag.active)
                ? simAuthBox.hostStage.theme.accentPrimary
                : simAuthBox.resolvedOuter
            border.width: Math.max(1.5, Math.round(simAuthBox.hostStage.inputOutlineThickness * simAuthBox.sFactor * 1.4))

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(12 * simAuthBox.sFactor)
                anchors.rightMargin: Math.round(12 * simAuthBox.sFactor)
                spacing: Math.round(8 * simAuthBox.sFactor)

                Text {
                    text: "󰌾"
                    font.family: simAuthBox.hostStage.font
                    font.pixelSize: Math.max(9, Math.round(16 * simAuthBox.sFactor))
                    color: simAuthBox.resolvedOuter
                }

                Text {
                    Layout.fillWidth: true
                    text: simAuthBox.hostStage.inputPlaceholder || "Password"
                    font.family: simAuthBox.hostStage.font
                    font.pixelSize: Math.max(8, Math.round(12 * simAuthBox.sFactor))
                    color: Qt.rgba(simAuthBox.resolvedFont.r, simAuthBox.resolvedFont.g, simAuthBox.resolvedFont.b, 0.5)
                    elide: Text.ElideRight
                }
            }
        }
    }

    // Floating Coordinates & Color Badge for Password Input
    Rectangle {
        visible: !simAuthBox.hostStage.previewMode && (simAuthBox.isInputSelected || inputDragArea.drag.active || inputBoxHover.hovered)
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: inputBadgeRow.implicitWidth + 14
        height: 18
        radius: 4
        color: simAuthBox.hostStage.theme.bgBase
        border.color: simAuthBox.hostStage.theme.accentPrimary
        border.width: 1
        z: 20

        RowLayout {
            id: inputBadgeRow
            anchors.centerIn: parent
            spacing: 4
            Rectangle {
                width: 6; height: 6; radius: 3
                color: simAuthBox.resolvedOuter
            }
            Text {
                id: inputBadgeTxt
                text: "Auth Box (" + simAuthBox.hostStage.liveInputX + ", " + simAuthBox.hostStage.liveInputY + ") • " + simAuthBox.hostStage.inputOuterColor
                font.family: simAuthBox.hostStage.font
                font.pixelSize: 9
                font.bold: true
                color: simAuthBox.hostStage.theme.accentPrimary
            }
        }
    }

    MouseArea {
        id: inputDragArea
        anchors.fill: parent
        preventStealing: true
        drag.target: simAuthBox
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0
        drag.maximumX: Math.max(0, simAuthBox.hostCanvas.width - simAuthBox.width)
        drag.minimumY: 0
        drag.maximumY: Math.max(0, simAuthBox.hostCanvas.height - simAuthBox.height)
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        onPressed: {
            simAuthBox.hostStage.selectedIndex = -2;
            simAuthBox.hostGuides.targetCenterX = simAuthBox.x + simAuthBox.width / 2;
            simAuthBox.hostGuides.targetCenterY = simAuthBox.y + simAuthBox.height / 2;
        }

        onPositionChanged: {
            if (drag.active) {
                let curCenterX = simAuthBox.x + simAuthBox.width / 2;
                let curCenterY = simAuthBox.y + simAuthBox.height / 2;
                simAuthBox.hostGuides.targetCenterX = curCenterX;
                simAuthBox.hostGuides.targetCenterY = curCenterY;
                simAuthBox.hostStage.applyMagneticSnap(simAuthBox.x, simAuthBox.y, simAuthBox.width, simAuthBox.height, -2);
            }
        }

        onReleased: {
            simAuthBox.hostGuides.snapVerticalActive = false;
            simAuthBox.hostGuides.snapHorizontalActive = false;

            let snapped = simAuthBox.hostStage.applyMagneticSnap(simAuthBox.x, simAuthBox.y, simAuthBox.width, simAuthBox.height, -2);
            simAuthBox.x = snapped.x;
            simAuthBox.y = snapped.y;

            let sFactor = simAuthBox.hostCanvas.scaleFactor;
            let curCenterX = simAuthBox.x + simAuthBox.width / 2;
            let curCenterY = simAuthBox.y + simAuthBox.height / 2;

            let newHalign = "center";
            if (curCenterX > simAuthBox.hostCanvas.width * 0.35 && curCenterX < simAuthBox.hostCanvas.width * 0.65) {
                newHalign = "center";
            } else if (curCenterX <= simAuthBox.hostCanvas.width * 0.35) {
                newHalign = "left";
            } else {
                newHalign = "right";
            }

            let newValign = "center";
            if (curCenterY < simAuthBox.hostCanvas.height * 0.35) {
                newValign = "top";
            } else if (curCenterY > simAuthBox.hostCanvas.height * 0.65) {
                newValign = "bottom";
            } else {
                newValign = "center";
            }

            let rawX = 0;
            if (newHalign === "center") {
                rawX = (curCenterX - (simAuthBox.hostCanvas.width / 2)) / sFactor;
            } else if (newHalign === "right") {
                rawX = ((simAuthBox.x + simAuthBox.width) - simAuthBox.hostCanvas.width) / sFactor;
            } else {
                rawX = simAuthBox.x / sFactor;
            }

            let rawY = 0;
            if (newValign === "center") {
                rawY = ((simAuthBox.hostCanvas.height / 2) - curCenterY) / sFactor;
            } else if (newValign === "bottom") {
                rawY = (simAuthBox.hostCanvas.height - (simAuthBox.y + simAuthBox.height)) / sFactor;
            } else {
                rawY = -(simAuthBox.y) / sFactor;
            }

            let finalX = Math.round(rawX);
            let finalY = Math.round(rawY);

            simAuthBox.hostStage.liveInputX = finalX;
            simAuthBox.hostStage.liveInputY = finalY;
            simAuthBox.hostStage.inputHalign = newHalign;
            simAuthBox.hostStage.inputValign = newValign;
            simAuthBox.hostStage.hasUnsavedMoves = false;
            simAuthBox.hostStage.inputMoved(finalX, finalY, newHalign, newValign);
        }
    }
}
