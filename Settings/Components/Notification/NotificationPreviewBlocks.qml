import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import "../../../notifications"
import "../.."
import "../Common"
import ".."

Item {
    id: previewBlocks
    visible: false
    width: 0
    height: 0

    required property var root
    required property color urgencyColor

  Component {
      id: previewInlineIconComp
      Rectangle {
          width: NotificationService.iconSize
          height: NotificationService.iconSize
          implicitWidth: width
          implicitHeight: height
          radius: NotificationService.iconRadius
          color: NotificationService.iconShowBg ? Qt.alpha(previewBlocks.urgencyColor, 0.16) : "transparent"
          border.color: root.selectedInspectorBlock === "icon" ? root.theme.accentPrimary : "transparent"
          border.width: root.selectedInspectorBlock === "icon" ? 1.5 : 0

          Text {
              anchors.centerIn: parent
              text: NotificationService.composerIcon || "󰂚"
              color: previewBlocks.urgencyColor
              font.pixelSize: Math.round(parent.width * 0.58)
              font.family: root.font
          }

          MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedInspectorBlock = "icon"
          }
      }
  }

  Component {
      id: previewAppNameComp
      Rectangle {
          implicitHeight: appNameTxt.implicitHeight + 4
          height: implicitHeight
          radius: 4
          color: root.selectedInspectorBlock === "appName" ? root.withAlpha(root.theme.accentPrimary, 0.12) : "transparent"

          Text {
              id: appNameTxt
              anchors.verticalCenter: parent.verticalCenter
              text: NotificationService.composerAppName || "notify-send"
              color: root.theme.textMuted
              font.pixelSize: NotificationService.appNameFontSize
              font.family: root.font
              elide: Text.ElideRight
              width: parent.width
          }

          MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedInspectorBlock = "appName"
          }
      }
  }

  Component {
      id: previewTimestampComp
      Rectangle {
          implicitWidth: tsTxt.implicitWidth + 8
          implicitHeight: tsTxt.implicitHeight + 4
          radius: 4
          color: root.selectedInspectorBlock === "timestamp" ? root.withAlpha(root.theme.accentPrimary, 0.15) : "transparent"

          Text {
              id: tsTxt
              anchors.centerIn: parent
              text: NotificationService.timestampFormat === "time" ? Qt.formatTime(new Date(), "hh:mm") : "Now"
              color: root.theme.textMuted
              font.pixelSize: Math.max(9, NotificationService.appNameFontSize - 1)
              font.family: root.font
          }

          MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedInspectorBlock = "timestamp"
          }
      }
  }

  Component {
      id: previewCloseComp
      Rectangle {
          width: 20
          height: 20
          implicitWidth: 20
          implicitHeight: 20
          radius: 10
          color: root.selectedInspectorBlock === "closeBtn"
              ? root.withAlpha(root.theme.accentPrimary, 0.18)
              : (simCloseHover.containsMouse ? root.theme.bgBorder : "transparent")

          Text {
              anchors.centerIn: parent
              text: "󰅖"
              color: simCloseHover.containsMouse ? root.theme.accentRed : root.theme.textMuted
              font.pixelSize: 12
              font.family: root.font
          }

          MouseArea {
              id: simCloseHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedInspectorBlock = "closeBtn"
          }
      }
  }

  Component {
      id: previewTitleComp
      Rectangle {
          implicitHeight: simTitleTxt.implicitHeight + 4
          height: implicitHeight
          radius: 4
          color: root.selectedInspectorBlock === "title" ? root.withAlpha(root.theme.accentPrimary, 0.1) : "transparent"
          visible: simTitleTxt.text !== ""

          Text {
              id: simTitleTxt
              width: parent.width
              anchors.verticalCenter: parent.verticalCenter
              text: NotificationService.composerTitle
              color: root.theme.textPrimary
              font.pixelSize: NotificationService.titleFontSize
              font.family: root.font
              font.bold: NotificationService.titleBold
              maximumLineCount: NotificationService.titleMaxLines
              wrapMode: NotificationService.titleMaxLines > 1 ? Text.Wrap : Text.NoWrap
              elide: Text.ElideRight
              horizontalAlignment: NotificationService.titleAlignment === "center"
                  ? Text.AlignHCenter
                  : (NotificationService.titleAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
          }

          MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedInspectorBlock = "title"
          }
      }
  }

  Component {
      id: previewSoloBodyComp
      Rectangle {
          implicitHeight: simSoloBodyTxt.implicitHeight + 4
          height: implicitHeight
          radius: 4
          color: root.selectedInspectorBlock === "body" ? root.withAlpha(root.theme.accentPrimary, 0.1) : "transparent"
          visible: simSoloBodyTxt.text !== ""

          Text {
              id: simSoloBodyTxt
              width: parent.width
              anchors.verticalCenter: parent.verticalCenter
              text: NotificationService.composerBody
              color: root.theme.textSecondary
              font.pixelSize: NotificationService.bodyFontSize
              font.family: root.font
              wrapMode: Text.Wrap
              maximumLineCount: NotificationService.bodyMaxLines
              elide: Text.ElideRight
              horizontalAlignment: NotificationService.bodyAlignment === "center"
                  ? Text.AlignHCenter
                  : (NotificationService.bodyAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
          }

          MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedInspectorBlock = "body"
          }
      }
  }

  Component {
      id: previewPairedBodyImgComp
      RowLayout {
          spacing: 10
          visible: NotificationService.composerBody !== "" || NotificationService.composerTitle !== "" || NotificationService.composerShowImage
          layoutDirection: NotificationService.imagePosition === "left" ? Qt.RightToLeft : Qt.LeftToRight

          ColumnLayout {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignTop
              spacing: 3

              Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: simPairedTitleTxt.implicitHeight + 2
                  height: implicitHeight
                  radius: 4
                  color: root.selectedInspectorBlock === "title" ? root.withAlpha(root.theme.accentPrimary, 0.1) : "transparent"
                  visible: NotificationService.isBlockVisible("title") && NotificationService.composerTitle !== ""

                  Text {
                      id: simPairedTitleTxt
                      width: parent.width
                      anchors.verticalCenter: parent.verticalCenter
                      text: NotificationService.composerTitle
                      color: root.theme.textPrimary
                      font.pixelSize: NotificationService.titleFontSize
                      font.family: root.font
                      font.bold: NotificationService.titleBold
                      maximumLineCount: NotificationService.titleMaxLines
                      wrapMode: NotificationService.titleMaxLines > 1 ? Text.Wrap : Text.NoWrap
                      elide: Text.ElideRight
                      horizontalAlignment: NotificationService.titleAlignment === "center"
                          ? Text.AlignHCenter
                          : (NotificationService.titleAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
                  }

                  MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.selectedInspectorBlock = "title"
                  }
              }

              Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: simBodyTxt.implicitHeight + 2
                  height: implicitHeight
                  radius: 4
                  color: root.selectedInspectorBlock === "body" ? root.withAlpha(root.theme.accentPrimary, 0.1) : "transparent"
                  visible: NotificationService.isBlockVisible("body") && NotificationService.composerBody !== ""

                  Text {
                      id: simBodyTxt
                      width: parent.width
                      anchors.verticalCenter: parent.verticalCenter
                      text: NotificationService.composerBody
                      color: root.theme.textSecondary
                      font.pixelSize: NotificationService.bodyFontSize
                      font.family: root.font
                      wrapMode: Text.Wrap
                      maximumLineCount: NotificationService.bodyMaxLines
                      elide: Text.ElideRight
                      horizontalAlignment: NotificationService.bodyAlignment === "center"
                          ? Text.AlignHCenter
                          : (NotificationService.bodyAlignment === "right" ? Text.AlignRight : Text.AlignLeft)
                  }

                  MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.selectedInspectorBlock = "body"
                  }
              }
          }

          Rectangle {
              Layout.preferredWidth: NotificationService.imageSize
              Layout.preferredHeight: NotificationService.imageSize
              Layout.alignment: Qt.AlignTop
              radius: NotificationService.imageRadius
              color: NotificationService.imageShowBg ? Qt.alpha(previewBlocks.urgencyColor, 0.15) : "transparent"
              border.color: NotificationService.imageShowRing ? Qt.alpha(previewBlocks.urgencyColor, 0.35) : "transparent"
              border.width: NotificationService.imageShowRing ? 1 : 0
              clip: true
              visible: NotificationService.composerShowImage

              Text {
                  anchors.centerIn: parent
                  text: "󰋩"
                  font.family: root.font
                  font.pixelSize: Math.round(NotificationService.imageSize * 0.45)
                  color: previewBlocks.urgencyColor
              }

              MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.selectedInspectorBlock = "image"
              }
          }
      }
  }

  Component {
      id: previewStandaloneImgComp
      Rectangle {
          readonly property bool isBanner: NotificationService.imagePosition === "banner"
          implicitHeight: isBanner ? Math.max(56, NotificationService.imageSize) : NotificationService.imageSize
          height: implicitHeight
          radius: NotificationService.imageRadius
          color: NotificationService.imageShowBg ? Qt.alpha(previewBlocks.urgencyColor, 0.15) : "transparent"
          border.color: NotificationService.imageShowRing ? Qt.alpha(previewBlocks.urgencyColor, 0.35) : "transparent"
          border.width: NotificationService.imageShowRing ? 1 : 0
          clip: true
          visible: NotificationService.composerShowImage

          RowLayout {
              anchors.centerIn: parent
              spacing: 6

              Text {
                  text: "󰋩"
                  font.family: root.font
                  font.pixelSize: 16
                  color: previewBlocks.urgencyColor
              }
              Text {
                  visible: parent.parent.isBanner
                  text: "Preview Thumbnail Banner"
                  font.family: root.font
                  font.pixelSize: 11
                  font.bold: true
                  color: root.theme.textSecondary
              }
          }

          MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedInspectorBlock = "image"
          }
      }
  }

  Component {
      id: previewButtonsComp
      RowLayout {
          spacing: 6
          visible: NotificationService.composerButtons && NotificationService.composerButtons.length > 0

          Item {
              visible: NotificationService.buttonStyle !== "fill"
                  && (NotificationService.buttonAlignment === "center" || NotificationService.buttonAlignment === "right")
              Layout.fillWidth: true
          }

          Repeater {
              model: NotificationService.composerButtons

              Rectangle {
                  id: simActBtn
                  required property var modelData
                  readonly property bool isReply: String(modelData.label || "").toLowerCase() === "reply"
                  readonly property bool isFill: NotificationService.buttonStyle === "fill" || NotificationService.buttonAlignment === "stretch"
                  readonly property bool isGhost: NotificationService.buttonStyle === "ghost"

                  Layout.preferredHeight: NotificationService.buttonHeight
                  Layout.preferredWidth: isFill ? 1 : (simActContent.implicitWidth + 24)
                  Layout.fillWidth: isFill
                  radius: NotificationService.buttonRadius
                  color: isReply
                      ? root.theme.accentPrimary
                      : (isGhost
                          ? (simActHover.containsMouse ? Qt.alpha(root.theme.accentPrimary, 0.16) : "transparent")
                          : (simActHover.containsMouse ? Qt.alpha(root.theme.accentPrimary, 0.28) : Qt.alpha(root.theme.accentPrimary, 0.12)))
                  border.width: root.selectedInspectorBlock === "buttons" ? 1.5 : (isGhost ? 0 : 1)
                  border.color: root.selectedInspectorBlock === "buttons"
                      ? root.theme.accentPrimary
                      : Qt.alpha(root.theme.accentPrimary, 0.28)

                  RowLayout {
                      id: simActContent
                      anchors.centerIn: parent
                      spacing: 5

                      Text {
                          visible: simActBtn.isReply
                          text: "󰈎"
                          color: root.theme.bgBase
                          font.pixelSize: 11
                          font.family: root.font
                      }

                      Text {
                          text: simActBtn.modelData.label || "Action"
                          color: simActBtn.isReply ? root.theme.bgBase : root.theme.accentPrimary
                          font.pixelSize: 11
                          font.bold: simActBtn.isReply || simActBtn.isFill
                          font.family: root.font
                      }
                  }

                  MouseArea {
                      id: simActHover
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.selectedInspectorBlock = "buttons"
                  }
              }
          }

          Item {
              visible: NotificationService.buttonStyle !== "fill"
                  && (NotificationService.buttonAlignment === "left" || NotificationService.buttonAlignment === "center")
              Layout.fillWidth: true
          }
      }
  }

  Component {
      id: previewProgressComp
      Rectangle {
          implicitHeight: NotificationService.progressHeight
          height: NotificationService.progressHeight
          radius: NotificationService.progressHeight / 2
          color: Qt.alpha(root.theme.bgSurface, 0.7)
          visible: NotificationService.composerUrgency !== NotificationUrgency.Critical || NotificationService.progressShowCritical

          Rectangle {
              height: parent.height
              width: parent.width * 0.68
              radius: parent.radius
              color: previewBlocks.urgencyColor
              opacity: 0.85
          }

          MouseArea {
              anchors.fill: parent
              anchors.margins: -5
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedInspectorBlock = "progressBar"
          }
      }
  }

    function getInlineComponent(blockId) {
        if (blockId === "icon" && !NotificationService.isAvatarIconEffective) return previewInlineIconComp;
        if (blockId === "appName") return previewAppNameComp;
        if (blockId === "timestamp") return previewTimestampComp;
        if (blockId === "closeBtn") return previewCloseComp;
        return null;
    }

    function getStackComponent(blockId, pairedTitleBodyAndImage, pairedBodyAndImage) {
        if (blockId === "title" && !pairedTitleBodyAndImage) return previewTitleComp;
        if (blockId === "body") return pairedBodyAndImage ? previewPairedBodyImgComp : previewSoloBodyComp;
        if (blockId === "image" && !pairedBodyAndImage) return previewStandaloneImgComp;
        if (blockId === "buttons") return previewButtonsComp;
        if (blockId === "progressBar") return previewProgressComp;
        return null;
    }
}
