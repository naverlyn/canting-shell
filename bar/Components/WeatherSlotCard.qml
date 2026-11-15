import QtQuick
import QtQuick.Layouts

Rectangle {
  id: slotCard

  required property var modelData
  required property var theme
  required property color accent
  required property string font
  required property string nerdFont

  Layout.fillWidth: true
  implicitHeight: 140
  radius: 9
  color: slotHover.hovered
    ? Qt.rgba(slotCard.theme.textPrimary.r, slotCard.theme.textPrimary.g, slotCard.theme.textPrimary.b, 0.08)
    : Qt.rgba(slotCard.theme.textPrimary.r, slotCard.theme.textPrimary.g, slotCard.theme.textPrimary.b, 0.04)
  border.color: slotHover.hovered
    ? slotCard.accent
    : Qt.rgba(slotCard.theme.bgBorder.r, slotCard.theme.bgBorder.g, slotCard.theme.bgBorder.b, 0.4)
  border.width: 1

  transform: Translate {
    y: slotHover.hovered ? -3 : 0
    Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
  }

  Behavior on color { ColorAnimation { duration: 150 } }
  Behavior on border.color { ColorAnimation { duration: 150 } }

  HoverHandler { id: slotHover }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 4

    // Time label (e.g. 󰖚 Morning)
    Row {
      Layout.fillWidth: true
      spacing: 6

      Text {
        width: 14
        horizontalAlignment: Text.AlignHCenter
        text: slotCard.modelData.timeIcon
        font.family: slotCard.nerdFont
        font.pixelSize: 13
        color: slotCard.accent
      }

      Text {
        text: slotCard.modelData.name
        font.family: slotCard.font
        font.pixelSize: 12
        font.bold: true
        color: slotCard.theme.textSecondary
      }
    }

    // Weather Icon & Temp
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 6

      Text {
        text: slotCard.modelData.weatherIcon
        font.family: slotCard.nerdFont
        font.pixelSize: 24
        color: slotCard.accent
      }

      Text {
        text: slotCard.modelData.temp
        font.family: slotCard.font
        font.pixelSize: 15
        font.bold: true
        color: slotCard.theme.textPrimary
      }
    }

    // Condition text
    Text {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignHCenter
      horizontalAlignment: Text.AlignHCenter
      text: slotCard.modelData.condition
      font.family: slotCard.font
      font.pixelSize: 12
      color: slotCard.theme.textPrimary
      elide: Text.ElideRight
    }

    Item { Layout.fillHeight: true }

    // Rain & Wind badges
    Rectangle {
      Layout.fillWidth: true
      height: 22
      radius: 5
      color: Qt.rgba(slotCard.theme.textPrimary.r, slotCard.theme.textPrimary.g, slotCard.theme.textPrimary.b, 0.06)

      Row {
        anchors.centerIn: parent
        spacing: 6

        Row {
          spacing: 4
          Text {
            width: 14
            horizontalAlignment: Text.AlignHCenter
            text: "󰖗"
            font.family: slotCard.nerdFont
            font.pixelSize: 11
            color: slotCard.accent
          }
          Text {
            text: slotCard.modelData.rain
            font.family: slotCard.font
            font.pixelSize: 11
            color: slotCard.theme.textMuted
          }
        }

        Text {
          text: "•"
          font.family: slotCard.font
          font.pixelSize: 8
          color: slotCard.theme.textMuted
        }

        Row {
          spacing: 4
          Text {
            width: 14
            horizontalAlignment: Text.AlignHCenter
            text: "󰖝"
            font.family: slotCard.nerdFont
            font.pixelSize: 11
            color: slotCard.accent
          }
          Text {
            text: slotCard.modelData.wind
            font.family: slotCard.font
            font.pixelSize: 11
            color: slotCard.theme.textMuted
          }
        }
      }
    }
  }
}
