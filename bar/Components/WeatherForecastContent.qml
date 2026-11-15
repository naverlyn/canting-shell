import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
  id: forecastContentWrapper
  required property var hostPopup
  Layout.fillWidth: true
  Layout.fillHeight: true

  property real contentOpacity: 1.0
  property real contentYOffset: 0.0

  Connections {
    target: forecastContentWrapper.hostPopup
    function onSelectedDayIndexChanged() {
      tabSwitchAnim.restart();
    }
  }

  SequentialAnimation {
    id: tabSwitchAnim
    ParallelAnimation {
      NumberAnimation { target: forecastContentWrapper; property: "contentOpacity"; to: 0.0; duration: 75; easing.type: Easing.OutQuad }
      NumberAnimation { target: forecastContentWrapper; property: "contentYOffset"; to: 6; duration: 75; easing.type: Easing.OutQuad }
    }
    ParallelAnimation {
      NumberAnimation { target: forecastContentWrapper; property: "contentOpacity"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
      NumberAnimation { target: forecastContentWrapper; property: "contentYOffset"; from: -6; to: 0; duration: 180; easing.type: Easing.OutCubic }
    }
  }

  Flickable {
    id: forecastFlick
    anchors.fill: parent
    anchors.topMargin: 2
    anchors.bottomMargin: 2
    opacity: forecastContentWrapper.contentOpacity
    y: forecastContentWrapper.contentYOffset
    clip: (forecastContentWrapper.hostPopup.selectedDayIndex === 3)
    interactive: (forecastContentWrapper.hostPopup.selectedDayIndex === 3)
    contentWidth: width
    contentHeight: forecastContainer.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
      policy: (forecastContentWrapper.hostPopup.selectedDayIndex === 3 && forecastFlick.contentHeight > forecastFlick.height)
        ? ScrollBar.AlwaysOn
        : ScrollBar.AlwaysOff
      width: 4
      contentItem: Rectangle {
        radius: 2
        color: forecastContentWrapper.hostPopup.theme.bgBorder
      }
    }

    ColumnLayout {
      id: forecastContainer
      width: forecastFlick.width - ((forecastContentWrapper.hostPopup.selectedDayIndex === 3 && forecastFlick.contentHeight > forecastFlick.height) ? 8 : 0)
      spacing: 10

      // If Loading with no data yet
      Text {
        visible: !forecastContentWrapper.hostPopup.hasValidData && forecastContentWrapper.hostPopup.isLoading
        text: "Loading forecast data..."
        font.family: forecastContentWrapper.hostPopup.font
        font.pixelSize: 12
        color: forecastContentWrapper.hostPopup.theme.textMuted
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 20
      }

      // If Error / No Data
      Text {
        visible: !forecastContentWrapper.hostPopup.hasValidData && !forecastContentWrapper.hostPopup.isLoading
        text: "Unable to retrieve weather forecast. Check connection or click refresh."
        font.family: forecastContentWrapper.hostPopup.font
        font.pixelSize: 12
        color: forecastContentWrapper.hostPopup.theme.textMuted
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 20
      }

      // Case 1: Single Day Selected (0, 1, or 2)
      WeatherDaySection {
        visible: forecastContentWrapper.hostPopup.hasValidData && forecastContentWrapper.hostPopup.selectedDayIndex >= 0 && forecastContentWrapper.hostPopup.selectedDayIndex < 3 && forecastContentWrapper.hostPopup.forecastDays.length > forecastContentWrapper.hostPopup.selectedDayIndex
        dayData: (forecastContentWrapper.hostPopup.forecastDays.length > forecastContentWrapper.hostPopup.selectedDayIndex && forecastContentWrapper.hostPopup.selectedDayIndex >= 0)
          ? forecastContentWrapper.hostPopup.forecastDays[forecastContentWrapper.hostPopup.selectedDayIndex]
          : null
        theme: forecastContentWrapper.hostPopup.theme
        accent: forecastContentWrapper.hostPopup.accent
        font: forecastContentWrapper.hostPopup.font
        nerdFont: forecastContentWrapper.hostPopup.effectiveNerdFont
        spacing: 8
      }

      // Case 2: All Days Selected (3)
      ColumnLayout {
        visible: forecastContentWrapper.hostPopup.hasValidData && forecastContentWrapper.hostPopup.selectedDayIndex === 3
        Layout.fillWidth: true
        spacing: 12

        Repeater {
          model: forecastContentWrapper.hostPopup.forecastDays

          delegate: WeatherDaySection {
            required property var modelData
            dayData: modelData
            theme: forecastContentWrapper.hostPopup.theme
            accent: forecastContentWrapper.hostPopup.accent
            font: forecastContentWrapper.hostPopup.font
            nerdFont: forecastContentWrapper.hostPopup.effectiveNerdFont
          }
        }

        // Clear bottom padding at the end of scrollable content
        Item {
          Layout.fillWidth: true
          implicitHeight: 18
        }
      }
    }
  }
}
