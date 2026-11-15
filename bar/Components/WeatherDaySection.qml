import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: daySection

  required property var dayData
  required property var theme
  required property color accent
  required property string font
  required property string nerdFont

  Layout.fillWidth: true
  spacing: 6

  RowLayout {
    Layout.fillWidth: true
    visible: daySection.dayData !== null

    Text {
      text: daySection.dayData ? daySection.dayData.fullDateLabel : ""
      font.family: daySection.font
      font.pixelSize: 13
      font.bold: true
      color: daySection.theme.textPrimary
    }

    Item { Layout.fillWidth: true }

    Text {
      text: daySection.dayData ? ("High: " + daySection.dayData.maxTemp + " · Low: " + daySection.dayData.minTemp) : ""
      font.family: daySection.font
      font.pixelSize: 12
      font.bold: true
      color: daySection.accent
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 6

    Repeater {
      model: (daySection.dayData && daySection.dayData.slots) ? daySection.dayData.slots : []

      delegate: WeatherSlotCard {
        theme: daySection.theme
        accent: daySection.accent
        font: daySection.font
        nerdFont: daySection.nerdFont
      }
    }
  }
}
