import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root

  required property var theme
  required property string font
  property color accent: theme.accentPrimary

  implicitHeight: grid.implicitHeight
  height: implicitHeight

  readonly property var metrics: [
    { icon: "󰻠", label: "CPU",     value: SystemInfo.cpuUsage || "0%",    color: theme.accentPrimary },
    { icon: "", label: "Memory",  value: SystemInfo.memoryUsage || "0%", color: theme.accentCyan },
    { icon: "󰔏", label: "Temp",    value: SystemInfo.temperature || "N/A",color: theme.accentOrange },
    { icon: "󰢮", label: "GPU",     value: SystemInfo.gpuUsage || "0%",    color: theme.accentGreen },
    { icon: "", label: "Disk",    value: SystemInfo.diskUsage || "0%",   color: theme.accentPrimary },
    { icon: "󰓅", label: "Network", value: "↓" + (SystemInfo.networkDownCompact || "0B") + " ↑" + (SystemInfo.networkUpCompact || "0B"), color: theme.accentCyan }
  ]

  GridLayout {
    id: grid
    anchors.left: parent.left
    anchors.right: parent.right
    columns: 3
    columnSpacing: 8
    rowSpacing: 8

    Repeater {
      model: root.metrics
      delegate: Rectangle {
        required property var modelData
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: 10
        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
        border.color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08)
        border.width: 1

        ColumnLayout {
          anchors.centerIn: parent
          width: parent.width - 12
          spacing: 3

          Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            Text {
              text: modelData.icon
              font.family: root.font
              font.pixelSize: 12
              color: modelData.color
            }
            Text {
              text: modelData.label
              font.family: root.font
              font.pixelSize: 10
              color: root.theme.textMuted
            }
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: modelData.value
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textPrimary
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
