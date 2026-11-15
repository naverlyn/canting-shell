import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: simAuthBox
    required property var stageRoot
    required property var canvasBox
    required property var dragGuides
    visible: !stageRoot.hasAuthModule
    readonly property real sFactor: canvasBox.scaleFactor
    readonly property bool isInputSelected: stageRoot.selectedIndex === -2
    readonly property color resolvedOuter: stageRoot.resolveColor(stageRoot.inputOuterColor)
    readonly property color resolvedInner: stageRoot.resolveColor(stageRoot.inputInnerColor)
    readonly property color resolvedFont: stageRoot.resolveColor(stageRoot.inputFontColor)

    readonly property real avatarSize: Math.round(104 * sFactor)
    readonly property real simInputW: Math.max(100, Math.round(stageRoot.inputWidth * sFactor))
    readonly property real simInputH: Math.max(22, Math.round(stageRoot.inputHeight * sFactor))

    width: Math.max(simInputW, avatarSize)
    height: authCol.implicitHeight
    z: isInputSelected || inputDragArea.drag.active ? 15 : 3
    scale: stageRoot.animAuthScale
    opacity: stageRoot.animModsOpacity
    transform: Translate { y: stageRoot.animAuthOffsetY }

    readonly property real targetX: {
        const curX = Number(stageRoot.liveInputX) || 0;
        if (stageRoot.inputHalign === "left") {
            return curX * sFactor;
        } else if (stageRoot.inputHalign === "right") {
            return canvasBox.width - width + (curX * sFactor);
        } else {
            return (canvasBox.width - width) / 2 + (curX * sFactor);
        }
    }

    readonly property real targetY: {
        const curY = Number(stageRoot.liveInputY) || 0;
        if (stageRoot.inputValign === "top") {
            return -(curY * sFactor);
        } else if (stageRoot.inputValign === "bottom") {
            return canvasBox.height - height - (curY * sFactor);
        } else {
            return (canvasBox.height - height) / 2 - (curY * sFactor);
        }
    }

    Binding on x {
        when: !inputDragArea.drag.active
        value: Math.max(2, Math.min(canvasBox.width - simAuthBox.width - 2, Math.round(simAuthBox.targetX)))
    }

    Binding on y {
        when: !inputDragArea.drag.active
        value: Math.max(2, Math.min(canvasBox.height - simAuthBox.height - 2, Math.round(simAuthBox.targetY)))
    }

    HoverHandler { id: inputBoxHover }

    ColumnLayout {
        id: authCol
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Math.max(4, Math.round(14 * simAuthBox.sFactor))

        // Avatar Circle
        Item {
            visible: stageRoot.showUser
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
                border.color: stageRoot.theme.accentGreen
                scale: stageRoot.animRippleScale
                opacity: stageRoot.animRippleOpacity
                visible: opacity > 0
            }

            Rectangle {
                id: avatarCircleBg
                anchors.fill: parent
                radius: width / 2
                color: simAuthBox.resolvedInner
                border.width: Math.max(1.5, Math.round(3 * simAuthBox.sFactor))
                border.color: (simAuthBox.isInputSelected || inputDragArea.drag.active)
                    ? stageRoot.theme.accentPrimary
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
                    font.family: stageRoot.font
                    font.pixelSize: Math.round(44 * simAuthBox.sFactor)
                    color: simAuthBox.resolvedOuter
                }
            }
        }

        // Username Text
        Text {
            visible: stageRoot.showUser
            Layout.alignment: Qt.AlignHCenter
            text: stageRoot.username
            font.family: stageRoot.font
            font.pixelSize: Math.max(9, Math.round(18 * simAuthBox.sFactor))
            font.bold: true
            color: stageRoot.resolveColor("$text")
            style: Text.Outline
            styleColor: stageRoot.theme.bgOverlay
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
                ? stageRoot.theme.accentPrimary
                : simAuthBox.resolvedOuter
            border.width: Math.max(1.5, Math.round(stageRoot.inputOutlineThickness * simAuthBox.sFactor * 1.4))

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(12 * simAuthBox.sFactor)
                anchors.rightMargin: Math.round(12 * simAuthBox.sFactor)
                spacing: Math.round(8 * simAuthBox.sFactor)

                Text {
                    text: "󰌾"
                    font.family: stageRoot.font
                    font.pixelSize: Math.max(9, Math.round(16 * simAuthBox.sFactor))
                    color: simAuthBox.resolvedOuter
                }

                Text {
                    Layout.fillWidth: true
                    text: stageRoot.inputPlaceholder || "Password"
                    font.family: stageRoot.font
                    font.pixelSize: Math.max(8, Math.round(12 * simAuthBox.sFactor))
                    color: Qt.rgba(simAuthBox.resolvedFont.r, simAuthBox.resolvedFont.g, simAuthBox.resolvedFont.b, 0.5)
                    elide: Text.ElideRight
                }
            }
        }
    }

    // Floating Coordinates & Color Badge for Password Input
    Rectangle {
        visible: !stageRoot.previewMode && (simAuthBox.isInputSelected || inputDragArea.drag.active || inputBoxHover.hovered)
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: inputBadgeRow.implicitWidth + 14
        height: 18
        radius: 4
        color: stageRoot.theme.bgBase
        border.color: stageRoot.theme.accentPrimary
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
                text: "Auth Box (" + stageRoot.liveInputX + ", " + stageRoot.liveInputY + ") • " + stageRoot.inputOuterColor
                font.family: stageRoot.font
                font.pixelSize: 9
                font.bold: true
                color: stageRoot.theme.accentPrimary
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
        drag.maximumX: Math.max(0, canvasBox.width - simAuthBox.width)
        drag.minimumY: 0
        drag.maximumY: Math.max(0, canvasBox.height - simAuthBox.height)
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        onPressed: {
            stageRoot.selectedIndex = -2;
            dragGuides.targetCenterX = simAuthBox.x + simAuthBox.width / 2;
            dragGuides.targetCenterY = simAuthBox.y + simAuthBox.height / 2;
        }

        onPositionChanged: {
            if (drag.active) {
                let curCenterX = simAuthBox.x + simAuthBox.width / 2;
                let curCenterY = simAuthBox.y + simAuthBox.height / 2;
                dragGuides.targetCenterX = curCenterX;
                dragGuides.targetCenterY = curCenterY;
                stageRoot.applyMagneticSnap(simAuthBox.x, simAuthBox.y, simAuthBox.width, simAuthBox.height, -2);
            }
        }

        onReleased: {
            dragGuides.snapVerticalActive = false;
            dragGuides.snapHorizontalActive = false;

            let snapped = stageRoot.applyMagneticSnap(simAuthBox.x, simAuthBox.y, simAuthBox.width, simAuthBox.height, -2);
            simAuthBox.x = snapped.x;
            simAuthBox.y = snapped.y;

            let sFactor = canvasBox.scaleFactor;
            let curCenterX = simAuthBox.x + simAuthBox.width / 2;
            let curCenterY = simAuthBox.y + simAuthBox.height / 2;

            let newHalign = "center";
            if (curCenterX > canvasBox.width * 0.35 && curCenterX < canvasBox.width * 0.65) {
                newHalign = "center";
            } else if (curCenterX <= canvasBox.width * 0.35) {
                newHalign = "left";
            } else {
                newHalign = "right";
            }

            let newValign = "center";
            if (curCenterY < canvasBox.height * 0.35) {
                newValign = "top";
            } else if (curCenterY > canvasBox.height * 0.65) {
                newValign = "bottom";
            } else {
                newValign = "center";
            }

            let rawX = 0;
            if (newHalign === "center") {
                rawX = (curCenterX - (canvasBox.width / 2)) / sFactor;
            } else if (newHalign === "right") {
                rawX = ((simAuthBox.x + simAuthBox.width) - canvasBox.width) / sFactor;
            } else {
                rawX = simAuthBox.x / sFactor;
            }

            let rawY = 0;
            if (newValign === "center") {
                rawY = ((canvasBox.height / 2) - curCenterY) / sFactor;
            } else if (newValign === "bottom") {
                rawY = (canvasBox.height - (simAuthBox.y + simAuthBox.height)) / sFactor;
            } else {
                rawY = -(simAuthBox.y) / sFactor;
            }

            let finalX = Math.round(rawX);
            let finalY = Math.round(rawY);

            stageRoot.liveInputX = finalX;
            stageRoot.liveInputY = finalY;
            stageRoot.inputHalign = newHalign;
            stageRoot.inputValign = newValign;
            stageRoot.hasUnsavedMoves = false;
            stageRoot.inputMoved(finalX, finalY, newHalign, newValign);
        }
    }
}
