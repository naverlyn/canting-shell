import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ".."

Rectangle {
    id: imgBox

    required property string imageSource
    required property color urgencyColor
    required property color secondaryTextColor
    required property string font
    property bool isBanner: false
    property int sourceWidth: NotificationService.imageSize * 2
    property int sourceHeight: NotificationService.imageSize * 2

    radius: NotificationService.imageRadius
    antialiasing: true
    color: NotificationService.imageShowBg ? Qt.alpha(imgBox.urgencyColor, 0.14) : "transparent"
    border.color: Qt.alpha(imgBox.urgencyColor, 0.3)
    border.width: 1

    Rectangle {
        id: imgMask
        anchors.fill: parent
        radius: NotificationService.imageRadius
        antialiasing: true
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.max(2, Math.round(width * 2)), Math.max(2, Math.round(height * 2)))
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: imgMask
            maskThresholdMin: 0.35
            maskSpreadAtMin: 0.3
        }

        Image {
            id: thumbImg
            anchors.fill: parent
            source: imgBox.imageSource
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: imgBox.sourceWidth
            sourceSize.height: imgBox.sourceHeight
            cache: false
            asynchronous: true
            smooth: true
            visible: status === Image.Ready
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6
        visible: thumbImg.status !== Image.Ready

        Text {
            text: "󰋩"
            font.family: imgBox.font
            font.pixelSize: imgBox.isBanner ? 16 : Math.round(NotificationService.imageSize * 0.45)
            color: imgBox.urgencyColor
        }

        Text {
            visible: imgBox.isBanner
            text: "Preview Thumbnail"
            font.family: imgBox.font
            font.pixelSize: 11
            font.bold: true
            color: imgBox.secondaryTextColor
        }
    }
}
