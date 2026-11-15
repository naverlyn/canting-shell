import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  required property var theme
  required property string font
  required property bool commandMode
  required property bool isExpanded

  Layout.fillWidth: true
  height: 32
  color: root.theme.bgSurface
  visible: root.isExpanded

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 16

    Row {
      spacing: 4
      Text { text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
      Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
      spacing: 4
      Text { text: "Tab"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
      Text { text: "switch mode"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
      spacing: 4
      Text { text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
      Text { text: root.commandMode ? "execute" : "launch"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
      spacing: 4
      Text { text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
      Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
    }

    Item { Layout.fillWidth: true }
  }
}
