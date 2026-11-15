import QtQuick
import QtQuick.Layouts

Rectangle {
  id: itemCard

  required property var modelData
  required property int index
  required property var theme
  required property string font
  required property bool isSelected
  required property bool panelVisible

  signal cardClicked(int idx, var item)
  signal copyClicked(var item)
  signal deleteClicked(var item)

  readonly property string category: modelData.category || "text"
  readonly property bool isImage: modelData.isBinary || category === "image"
  readonly property bool isColor: category === "color"
  readonly property bool isHovered: cardMouse.containsMouse || copyBtnMouse.containsMouse || delBtnMouse.containsMouse

  height: isImage ? 76 : (isColor ? 54 : (previewTextItem.lineCount > 1 ? 64 : 52))
  radius: 8
  scale: cardMouse.pressed ? 0.985 : 1.0

  color: isSelected
    ? (itemCard.theme.bgSelected ?? Qt.rgba(itemCard.theme.accentPrimary.r, itemCard.theme.accentPrimary.g, itemCard.theme.accentPrimary.b, 0.18))
    : (itemCard.isHovered ? Qt.rgba(itemCard.theme.textPrimary.r, itemCard.theme.textPrimary.g, itemCard.theme.textPrimary.b, 0.08) : itemCard.theme.bgSurface)
  border.color: isSelected
    ? itemCard.theme.accentPrimary
    : (itemCard.isHovered ? Qt.rgba(itemCard.theme.accentPrimary.r, itemCard.theme.accentPrimary.g, itemCard.theme.accentPrimary.b, 0.45) : itemCard.theme.bgBorder)
  border.width: isSelected ? 1.5 : 1

  Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
  Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
  Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 12
    spacing: 12

    // Left Visual: Image Thumbnail / Color Circle
    Item {
      visible: itemCard.isImage || itemCard.isColor
      width: itemCard.isImage ? 64 : 28
      height: itemCard.isImage ? 56 : 28
      Layout.alignment: Qt.AlignVCenter

      Rectangle {
        visible: itemCard.isImage
        anchors.fill: parent
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.25)
        border.color: itemCard.theme.bgBorder
        border.width: 1
        clip: true

        Image {
          anchors.fill: parent
          source: (itemCard.panelVisible && itemCard.modelData.thumbPath) ? ("file://" + itemCard.modelData.thumbPath) : ""
          sourceSize.width: 128
          sourceSize.height: 112
          cache: false
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          smooth: true
        }

        Text {
          anchors.centerIn: parent
          text: "IMAGE"
          font.family: itemCard.font
          font.pixelSize: 10
          font.bold: true
          color: itemCard.theme.textMuted
          visible: !itemCard.modelData.thumbPath
        }
      }

      Rectangle {
        visible: itemCard.isColor
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 14
        color: itemCard.modelData.preview.trim()
        border.color: "#ffffff"
        border.width: 1.5
      }
    }

    // Center Content Info
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 3
      Layout.alignment: Qt.AlignVCenter

      RowLayout {
        spacing: 6
        visible: itemCard.isImage || itemCard.category === "link" || itemCard.category === "code" || itemCard.isColor

        Text {
          text: {
            if (itemCard.isImage) return itemCard.modelData.imgMeta || "IMAGE";
            if (itemCard.isColor) return "COLOR SWATCH";
            if (itemCard.category === "link") return "LINK / URL";
            if (itemCard.category === "code") return "CODE SNIPPET";
            return "";
          }
          font.family: itemCard.font
          font.pixelSize: 9
          font.bold: true
          color: {
            if (itemCard.category === "link") return itemCard.theme.accentCyan;
            if (itemCard.category === "code") return itemCard.theme.accentPrimary;
            return itemCard.theme.textMuted;
          }
        }
      }

      Text {
        id: previewTextItem
        Layout.fillWidth: true
        text: itemCard.isImage ? (itemCard.modelData.imgMeta || "Image from clipboard") : itemCard.modelData.preview
        font.family: (itemCard.category === "code" || itemCard.isColor) ? "monospace" : itemCard.font
        font.pixelSize: itemCard.category === "code" ? 11 : 12
        font.bold: itemCard.isSelected
        color: itemCard.category === "link"
          ? itemCard.theme.accentCyan
          : (itemCard.isSelected ? itemCard.theme.textPrimary : itemCard.theme.textSecondary)
        elide: Text.ElideRight
        maximumLineCount: itemCard.isImage ? 1 : 2
        wrapMode: Text.WrapAnywhere
      }
    }

    // Right Action Buttons
    RowLayout {
      spacing: 6
      opacity: (itemCard.isHovered || itemCard.isSelected) ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { duration: 120 } }
      Layout.alignment: Qt.AlignVCenter

      Rectangle {
        implicitWidth: copyBtnLabel.implicitWidth + 16
        height: 26
        radius: 5
        scale: copyBtnMouse.pressed ? 0.93 : 1.0
        color: copyBtnMouse.containsMouse
          ? itemCard.theme.accentPrimary
          : Qt.rgba(itemCard.theme.accentPrimary.r, itemCard.theme.accentPrimary.g, itemCard.theme.accentPrimary.b, 0.22)
        border.color: itemCard.theme.accentPrimary
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

        Text {
          id: copyBtnLabel
          anchors.centerIn: parent
          text: "Copy"
          font.family: itemCard.font
          font.pixelSize: 10
          font.bold: true
          color: copyBtnMouse.containsMouse ? itemCard.theme.bgBase : itemCard.theme.accentPrimary
        }

        MouseArea {
          id: copyBtnMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: itemCard.copyClicked(itemCard.modelData)
        }
      }

      Rectangle {
        implicitWidth: delBtnLabel.implicitWidth + 14
        height: 26
        radius: 5
        scale: delBtnMouse.pressed ? 0.93 : 1.0
        color: delBtnMouse.containsMouse ? (itemCard.theme.accentRed ?? "#e05252") : Qt.rgba(1, 1, 1, 0.08)
        border.color: delBtnMouse.containsMouse ? itemCard.theme.accentRed : itemCard.theme.bgBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

        Text {
          id: delBtnLabel
          anchors.centerIn: parent
          text: "Delete"
          font.family: itemCard.font
          font.pixelSize: 10
          font.bold: true
          color: delBtnMouse.containsMouse ? "#ffffff" : itemCard.theme.textMuted
        }

        MouseArea {
          id: delBtnMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: itemCard.deleteClicked(itemCard.modelData)
        }
      }
    }
  }

  MouseArea {
    id: cardMouse
    anchors.fill: parent
    anchors.rightMargin: 130
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: itemCard.cardClicked(itemCard.index, itemCard.modelData)
  }
}
