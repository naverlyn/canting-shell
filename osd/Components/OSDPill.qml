import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  required property var theme
  required property string font
  required property bool active
  required property bool isHorizontal
  required property string iconText
  required property real value
  required property string valueText
  property bool muted: false
  property string accessibleLabel: ""

  readonly property real clampedValue: Math.max(0, Math.min(1, root.muted ? 0 : root.value))

  visible: root.active || opacity > 0.001
  implicitWidth: root.isHorizontal ? 240 : 36
  implicitHeight: root.isHorizontal ? 44 : 200
  width: implicitWidth
  height: implicitHeight
  radius: root.isHorizontal ? 22 : 18
  color: root.theme.bgBase
  border.color: root.theme.bgBorder
  border.width: 1
  opacity: root.active ? 1 : 0
  clip: true

  Behavior on opacity { NumberAnimation { duration: 150 } }
  Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  Behavior on radius { NumberAnimation { duration: 160 } }

  Accessible.role: Accessible.ProgressBar
  Accessible.name: root.accessibleLabel

  // Horizontal layout
  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 16
    spacing: 12
    visible: root.isHorizontal

    Text {
      text: root.iconText
      color: root.muted ? root.theme.textMuted : root.theme.accentPrimary
      font.pixelSize: 16
      font.family: root.font
      Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 6
      radius: 3
      color: root.theme.bgSurface
      border.color: root.theme.bgBorder
      border.width: 1
      clip: true
      Layout.alignment: Qt.AlignVCenter

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(0, Math.min(parent.width, parent.width * root.clampedValue))
        radius: 3
        color: root.muted ? root.theme.textMuted : root.theme.accentPrimary

        Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
      }
    }

    Text {
      text: root.valueText
      color: root.muted ? root.theme.textMuted : root.theme.textPrimary
      font.pixelSize: 11
      font.bold: true
      font.family: root.font
      Layout.alignment: Qt.AlignVCenter
      Layout.preferredWidth: 42
      horizontalAlignment: Text.AlignRight
    }
  }

  // Vertical layout
  ColumnLayout {
    anchors.fill: parent
    anchors.topMargin: 12
    anchors.bottomMargin: 12
    spacing: 8
    visible: !root.isHorizontal

    Text {
      text: root.valueText
      color: root.theme.textSecondary
      font.pixelSize: 10
      font.family: root.font
      Layout.alignment: Qt.AlignHCenter
    }

    Rectangle {
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignHCenter
      width: 8
      radius: 4
      color: root.theme.bgSurface
      border.color: root.theme.bgBorder
      border.width: 1
      clip: true

      Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 2
        height: Math.max(0, (parent.height - 4) * root.clampedValue)
        radius: 3
        color: root.muted ? root.theme.textMuted : root.theme.accentPrimary

        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
      }
    }

    Text {
      text: root.iconText
      color: root.muted ? root.theme.textMuted : root.theme.accentPrimary
      font.pixelSize: 15
      font.family: root.font
      Layout.alignment: Qt.AlignHCenter
    }
  }
}
