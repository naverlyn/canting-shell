import QtQuick

Item {
    id: resizeHandlesRoot
    required property var winCard
    anchors.fill: parent

            // Right Edge
            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: -4
                width: 8
                cursorShape: Qt.SizeHorCursor
                property real startX
                property real startW
                onPressed: (mouse) => { startX = mouse.x; startW = winCard.width; }
                onPositionChanged: (mouse) => {
                    if (pressed) winCard.width = Math.max(winCard.minWidth, startW + (mouse.x - startX));
                }
            }

            // Bottom Edge
            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -4
                height: 8
                cursorShape: Qt.SizeVerCursor
                property real startY
                property real startH
                onPressed: (mouse) => { startY = mouse.y; startH = winCard.height; }
                onPositionChanged: (mouse) => {
                    if (pressed) winCard.height = Math.max(winCard.minHeight, startH + (mouse.y - startY));
                }
            }

            // Left Edge
            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: -4
                width: 8
                cursorShape: Qt.SizeHorCursor
                property real startMouseX
                property real startWinX
                property real startW
                onPressed: (mouse) => {
                    startMouseX = mouse.x;
                    startWinX = winCard.x;
                    startW = winCard.width;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dx = mouse.x - startMouseX;
                        let nw = Math.max(winCard.minWidth, startW - dx);
                        winCard.x = startWinX + (startW - nw);
                        winCard.width = nw;
                    }
                }
            }

            // Top Edge
            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: -4
                height: 8
                cursorShape: Qt.SizeVerCursor
                property real startMouseY
                property real startWinY
                property real startH
                onPressed: (mouse) => {
                    startMouseY = mouse.y;
                    startWinY = winCard.y;
                    startH = winCard.height;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dy = mouse.y - startMouseY;
                        let nh = Math.max(winCard.minHeight, startH - dy);
                        winCard.y = startWinY + (startH - nh);
                        winCard.height = nh;
                    }
                }
            }

            // Bottom-Right Corner
            MouseArea {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 14; height: 14
                anchors.margins: -4
                cursorShape: Qt.SizeFDiagCursor
                property point startMouse
                property real startW
                property real startH
                onPressed: (mouse) => {
                    startMouse = Qt.point(mouse.x, mouse.y);
                    startW = winCard.width;
                    startH = winCard.height;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        winCard.width = Math.max(winCard.minWidth, startW + (mouse.x - startMouse.x));
                        winCard.height = Math.max(winCard.minHeight, startH + (mouse.y - startMouse.y));
                    }
                }
            }

            // Top-Right Corner
            MouseArea {
                anchors.right: parent.right
                anchors.top: parent.top
                width: 14; height: 14
                anchors.margins: -4
                cursorShape: Qt.SizeBDiagCursor
                property point startMouse
                property real startW
                property real startH
                property real startY
                onPressed: (mouse) => {
                    startMouse = Qt.point(mouse.x, mouse.y);
                    startW = winCard.width;
                    startH = winCard.height;
                    startY = winCard.y;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        winCard.width = Math.max(winCard.minWidth, startW + (mouse.x - startMouse.x));
                        let dy = mouse.y - startMouse.y;
                        let nh = Math.max(winCard.minHeight, startH - dy);
                        winCard.y = startY + (startH - nh);
                        winCard.height = nh;
                    }
                }
            }

            // Bottom-Left Corner
            MouseArea {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: 14; height: 14
                anchors.margins: -4
                cursorShape: Qt.SizeBDiagCursor
                property point startMouse
                property real startW
                property real startH
                property real startX
                onPressed: (mouse) => {
                    startMouse = Qt.point(mouse.x, mouse.y);
                    startW = winCard.width;
                    startH = winCard.height;
                    startX = winCard.x;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dx = mouse.x - startMouse.x;
                        let nw = Math.max(winCard.minWidth, startW - dx);
                        winCard.x = startX + (startW - nw);
                        winCard.width = nw;
                        winCard.height = Math.max(winCard.minHeight, startH + (mouse.y - startMouse.y));
                    }
                }
            }

            // Top-Left Corner
            MouseArea {
                anchors.left: parent.left
                anchors.top: parent.top
                width: 14; height: 14
                anchors.margins: -4
                cursorShape: Qt.SizeFDiagCursor
                property point startMouse
                property real startW
                property real startH
                property real startX
                property real startY
                onPressed: (mouse) => {
                    startMouse = Qt.point(mouse.x, mouse.y);
                    startW = winCard.width;
                    startH = winCard.height;
                    startX = winCard.x;
                    startY = winCard.y;
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dx = mouse.x - startMouse.x;
                        let dy = mouse.y - startMouse.y;
                        let nw = Math.max(winCard.minWidth, startW - dx);
                        let nh = Math.max(winCard.minHeight, startH - dy);
                        winCard.x = startX + (startW - nw);
                        winCard.y = startY + (startH - nh);
                        winCard.width = nw;
                        winCard.height = nh;
                    }
                }
            }
}
