import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  required property var theme
  required property string font
  required property string iconText
  required property string label
  property string shortcutHint: ""
  property bool active: false

  signal triggered()

  implicitWidth: Math.max(82, col.implicitWidth + 24)
  implicitHeight: 68
  radius: 12
  color: root.active
    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, btnHover.hovered ? 0.36 : 0.24)
    : (btnHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
  border.color: root.active
    ? root.theme.accentPrimary
    : (btnHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder)
  border.width: 1
  scale: btnArea.pressed ? 0.95 : 1.0

  Behavior on color { ColorAnimation { duration: 120 } }
  Behavior on border.color { ColorAnimation { duration: 120 } }
  Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

  HoverHandler { id: btnHover }

  MouseArea {
    id: btnArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.triggered()
  }

  ColumnLayout {
    id: col
    anchors.centerIn: parent
    spacing: 4

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: root.iconText
      font.family: root.font
      font.pixelSize: 20
      color: (root.active || btnHover.hovered) ? root.theme.accentPrimary : root.theme.textPrimary
    }

    Row {
      Layout.alignment: Qt.AlignHCenter
      spacing: 4

      Text {
        text: root.label
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.theme.textPrimary
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        visible: root.shortcutHint !== ""
        text: root.shortcutHint
        font.family: root.font
        font.pixelSize: 9
        color: root.theme.textMuted
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
