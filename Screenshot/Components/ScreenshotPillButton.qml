import QtQuick

Rectangle {
  id: root

  required property var theme
  required property string font
  required property string text
  property bool active: false
  property int fixedWidth: 0

  signal triggered()

  implicitWidth: root.fixedWidth > 0 ? root.fixedWidth : (pillLbl.implicitWidth + 14)
  implicitHeight: 24
  height: 24
  radius: 12
  color: root.active
    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, pillHover.hovered ? 0.36 : 0.24)
    : (pillHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
  border.color: (root.active || pillHover.hovered) ? root.theme.accentPrimary : root.theme.bgBorder
  border.width: 1
  scale: pillArea.pressed ? 0.92 : 1.0

  Behavior on color { ColorAnimation { duration: 120 } }
  Behavior on border.color { ColorAnimation { duration: 120 } }
  Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

  HoverHandler { id: pillHover }

  MouseArea {
    id: pillArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.triggered()
  }

  Text {
    id: pillLbl
    anchors.centerIn: parent
    text: root.text
    font.family: root.font
    font.pixelSize: 11
    font.bold: root.active
    color: (root.active || pillHover.hovered) ? root.theme.accentPrimary : root.theme.textSecondary

    Behavior on color { ColorAnimation { duration: 120 } }
  }
}
