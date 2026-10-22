import Quickshell
import ".."
import QtQuick
import QtQuick.Layouts

Rectangle {
  id: previewRoot
  required property var hostRoot
  anchors.fill: parent
  color: Qt.rgba(0, 0, 0, 0.88)
  visible: hostRoot.previewPath !== ""
  z: 99

  MouseArea {
    anchors.fill: parent
    onClicked: hostRoot.previewPath = ""
  }

  ColumnLayout {
    anchors.centerIn: parent
    width: parent.width * 0.88
    height: parent.height * 0.88
    spacing: 12

    Image {
      Layout.fillWidth: true
      Layout.fillHeight: true
      source: hostRoot.previewPath !== "" ? "file://" + hostRoot.previewPath : ""
      fillMode: Image.PreserveAspectFit
      asynchronous: true
    }

    // Action Controls Container
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 10

      // Row 1: Mode selector (text-only segmented bar)
      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        Text {
          text: "Type:"
          font.family: hostRoot.font
          font.pixelSize: 11
          font.bold: true
          color: Qt.rgba(1, 1, 1, 0.75)
        }

        Rectangle {
          id: pModeTrack
          implicitWidth: 260
          height: 30
          radius: 7
          color: hostRoot.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.4)
          border.color: hostRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
          border.width: 1
          clip: true

          readonly property var typeList: ["crop", "fit", "stretch", "no"]
          readonly property int activeIdx: {
            const m = (WallpaperService.resizeMode === "scale" || WallpaperService.resizeMode === "fill") ? "crop"
                    : (WallpaperService.resizeMode === "center" ? "no" : WallpaperService.resizeMode);
            const idx = typeList.indexOf(m);
            return idx !== -1 ? idx : 0;
          }
          readonly property real cellWidth: (width - 6 - (3 * 4)) / 4

          Rectangle {
            id: pModeThumb
            y: 3
            height: parent.height - 6
            width: pModeTrack.cellWidth
            x: 3 + pModeTrack.activeIdx * (pModeTrack.cellWidth + 4)
            radius: 5
            color: hostRoot.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)
            border.color: hostRoot.theme.accentPrimary
            border.width: 1

            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
          }

          RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 4

            Repeater {
              model: [
                { label: "Fill",    value: "crop" },
                { label: "Fit",     value: "fit" },
                { label: "Stretch", value: "stretch" },
                { label: "Center",  value: "no" }
              ]

              delegate: Rectangle {
                id: pModeBtn
                required property var modelData
                required property int index
                readonly property bool isSel: pModeTrack.activeIdx === index

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 5
                color: !isSel && pModeHov.hovered ? (hostRoot.theme.bgHover ?? Qt.rgba(1, 1, 0.08)) : "transparent"
                Behavior on color { ColorAnimation { duration: 140 } }

                HoverHandler { id: pModeHov }

                Text {
                  anchors.centerIn: parent
                  text: pModeBtn.modelData.label
                  font.family: hostRoot.font
                  font.pixelSize: 11
                  font.bold: pModeBtn.isSel
                  color: pModeBtn.isSel ? hostRoot.theme.textPrimary : (hostRoot.theme.textSecondary ?? Qt.rgba(1, 1, 1, 0.7))
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    WallpaperService.setWallpaperType(pModeBtn.modelData.value);
                  }
                }
              }
            }
          }
        }
      }

      // Row 2: Action buttons (Text-only, no icons, prettier labels)
      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10

        // Close
        Rectangle {
          implicitWidth: closeText.implicitWidth + 24
          height: 34
          radius: 8
          color: closeHov.hovered ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
          border.color: Qt.rgba(1, 1, 1, 0.15)
          border.width: 1
          scale: closeHov.hovered ? 1.03 : 1.0
          HoverHandler { id: closeHov }

          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            id: closeText
            anchors.centerIn: parent
            text: "Close"
            font.family: hostRoot.font
            font.pixelSize: 12
            color: "#ffffff"
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: hostRoot.previewPath = ""
          }
        }

        // Set Primary
        Rectangle {
          implicitWidth: setAText.implicitWidth + 24
          height: 34
          radius: 8
          color: setAHov.hovered ? (hostRoot.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.15)) : (hostRoot.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.08))
          border.color: hostRoot.theme.accentPrimary
          border.width: 1
          scale: setAHov.hovered ? 1.03 : 1.0
          HoverHandler { id: setAHov }

          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            id: setAText
            anchors.centerIn: parent
            text: WallpaperService.hasMultipleMonitors
              ? "Set Primary (" + WallpaperService.displayAName + ")"
              : "Apply Wallpaper"
            font.family: hostRoot.font
            font.pixelSize: 11
            font.bold: true
            color: "#ffffff"
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              WallpaperService.setWallpaper(hostRoot.previewPath, WallpaperService.hasMultipleMonitors ? "primary" : "all", WallpaperService.resizeMode);
              hostRoot.previewPath = "";
            }
          }
        }

        // Set Secondary
        Rectangle {
          visible: WallpaperService.hasMultipleMonitors
          implicitWidth: setBText.implicitWidth + 24
          height: 34
          radius: 8
          color: setBHov.hovered ? (hostRoot.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.15)) : (hostRoot.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.08))
          border.color: hostRoot.theme.accentCyan ?? hostRoot.theme.accentPrimary
          border.width: 1
          scale: setBHov.hovered ? 1.03 : 1.0
          HoverHandler { id: setBHov }

          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            id: setBText
            anchors.centerIn: parent
            text: "Set Secondary (" + WallpaperService.displayBName + ")"
            font.family: hostRoot.font
            font.pixelSize: 11
            font.bold: true
            color: "#ffffff"
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              WallpaperService.setWallpaper(hostRoot.previewPath, "secondary", WallpaperService.resizeMode);
              hostRoot.previewPath = "";
            }
          }
        }

        // Apply to All
        Rectangle {
          visible: WallpaperService.hasMultipleMonitors
          implicitWidth: applyBothText.implicitWidth + 26
          height: 34
          radius: 8
          color: applyBothHov.hovered ? (hostRoot.theme.accentCyan ?? hostRoot.theme.accentPrimary) : hostRoot.theme.accentPrimary
          scale: applyBothHov.hovered ? 1.03 : 1.0
          HoverHandler { id: applyBothHov }

          Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            id: applyBothText
            anchors.centerIn: parent
            text: "Apply to All Displays"
            font.family: hostRoot.font
            font.pixelSize: 12
            font.bold: true
            color: hostRoot.theme.bgBase
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              WallpaperService.setWallpaper(hostRoot.previewPath, "all", WallpaperService.resizeMode);
              hostRoot.previewPath = "";
            }
          }
        }
      }
    }
  }
}
