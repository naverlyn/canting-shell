import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
  id: panel

  // Not required - intentionally null when no monitor is selected
  property var monitor:     null
  property var allMonitors: []
  required property var theme
  required property string font

  signal modeSelected(string mode)
  signal scaleSelected(real scale)      // not scaleChanged - conflicts with Item.scale built-in
  signal transformChanged(int transform)
  signal enableToggled(bool enabled)    // not enabledChanged - conflicts with Item.enabled built-in
  signal mirrorChanged(string mirrorOf)

  property bool modePickerOpen:   false
  property bool mirrorPickerOpen: false

  // Close open pickers when the selected monitor changes
  onMonitorChanged: {
    modePickerOpen   = false;
    mirrorPickerOpen = false;
    modeDropdown.close();
    mirrorDropdown.close();
  }

  // Mode dropdown overlay
  Popup {
    id: modeDropdown
    parent: modePill
    x: 0
    y: modePill.height + 4
    width: modePill.width
    padding: 1  // background border is drawn inward, so contentItem overlaps it without this
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    enter: Transition {
      NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
      NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    }
    exit: Transition {
      NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.OutCubic }
      NumberAnimation { property: "scale"; from: 1.0; to: 0.96; duration: 120; easing.type: Easing.OutCubic }
    }

    onOpened: panel.modePickerOpen   = true
    onClosed: panel.modePickerOpen   = false

    background: Rectangle {
      radius: 8
      color: panel.theme.bgSurface
      border.color: panel.theme.accentPrimary
      border.width: 1
    }

    contentItem: ListView {
      id: modeList
      implicitHeight: Math.min(contentHeight + 2, 180)
      model: (panel.monitor && panel.monitor.availableModes) ? panel.monitor.availableModes : []
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      delegate: Rectangle {
        required property string modelData
        width: modeList.width
        height: 28
        radius: 4
        color: modelData === (panel.monitor ? panel.monitor.selectedMode : "")
               ? panel.theme.accentPrimary
               : (modeItemArea.containsMouse ? (panel.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
          anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
          spacing: 0

          Text {
            text: modelData.split("@")[0]
            color: modelData === (panel.monitor ? panel.monitor.selectedMode : "") ? panel.theme.bgBase : panel.theme.textPrimary
            font { pixelSize: 11; family: panel.font }
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - rateText.width
          }
          Text {
            id: rateText
            text: "@" + (modelData.split("@")[1] ?? "")
            color: modelData === (panel.monitor ? panel.monitor.selectedMode : "") ? panel.theme.bgBase : panel.theme.textMuted
            font { pixelSize: 11; family: panel.font }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          id: modeItemArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            panel.modeSelected(modelData);
            modeDropdown.close();
          }
        }
      }
    }
  }

  // Mirror dropdown overlay
  Popup {
    id: mirrorDropdown
    parent: mirrorPill
    x: 0
    y: mirrorPill.height + 4
    width: mirrorPill.width
    padding: 1  // background border is drawn inward, so contentItem overlaps it without this
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    enter: Transition {
      NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
      NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    }
    exit: Transition {
      NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.OutCubic }
      NumberAnimation { property: "scale"; from: 1.0; to: 0.96; duration: 120; easing.type: Easing.OutCubic }
    }

    onOpened: panel.mirrorPickerOpen = true
    onClosed: panel.mirrorPickerOpen = false

    background: Rectangle {
      radius: 8
      color: panel.theme.bgSurface
      border.color: panel.theme.accentPrimary
      border.width: 1
    }

    contentItem: ListView {
      id: mirrorList
      implicitHeight: Math.min(contentHeight + 2, 150)
      model: {
        if (panel.monitor === null) return [];
        const opts = [""];
        for (const m of panel.allMonitors) {
          if (m.name !== panel.monitor.name) opts.push(m.name);
        }
        return opts;
      }
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      delegate: Rectangle {
        required property string modelData
        width: mirrorList.width
        height: 28
        radius: 4
        color: modelData === (panel.monitor ? panel.monitor.mirrorOf : "")
               ? panel.theme.accentPrimary
               : (mirrorItemArea.containsMouse ? (panel.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
          anchors { fill: parent; leftMargin: 10 }
          text: modelData === "" ? "None" : modelData
          color: modelData === (panel.monitor ? panel.monitor.mirrorOf : "")
                 ? panel.theme.bgBase
                 : (modelData === "" ? panel.theme.textMuted : panel.theme.textPrimary)
          font { pixelSize: 11; family: panel.font }
          verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
          id: mirrorItemArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            panel.mirrorChanged(modelData);
            mirrorDropdown.close();
          }
        }
      }
    }
  }

  // ScrollView guards its content against null monitor
  ScrollView {
    anchors.fill: parent
    clip: true
    contentWidth: availableWidth
    visible: panel.monitor !== null

    ColumnLayout {
      width: panel.width
      spacing: 12

      // Monitor identity
      Text {
        Layout.fillWidth: true
        text: panel.monitor ? panel.monitor.name : ""
        color: panel.theme.textPrimary
        font { pixelSize: 14; bold: true; family: panel.font }
      }
      Text {
        Layout.fillWidth: true
        text: (panel.monitor && panel.monitor.description) ? panel.monitor.description : ""
        color: panel.theme.textMuted
        font { pixelSize: 11; family: panel.font }
        elide: Text.ElideRight
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Resolution section
      Text {
        text: "Resolution"
        color: panel.theme.textSecondary
        font { pixelSize: 11; family: panel.font }
      }

      // Collapsed mode pill
      Rectangle {
        id: modePill
        Layout.fillWidth: true
        height: 32
        radius: 8
        color: panel.theme.bgSurface
        border.color: panel.modePickerOpen ? panel.theme.accentPrimary : panel.theme.bgBorder
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          spacing: 0

          Text {
            text: (panel.monitor && panel.monitor.selectedMode) ? panel.monitor.selectedMode.replace("Hz", "") : ""
            color: panel.theme.textPrimary
            font { pixelSize: 12; family: panel.font }
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 20
            elide: Text.ElideRight
          }
          Text {
            text: panel.modePickerOpen ? "▴" : "▾"
            color: panel.theme.textMuted
            font { pixelSize: 16; family: panel.font }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (panel.modePickerOpen) {
              modeDropdown.close();
            } else {
              mirrorDropdown.close();
              modeDropdown.open();
            }
          }
        }
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Scale section
      Text {
        text: "Scale"
        color: panel.theme.textSecondary
        font { pixelSize: 11; family: panel.font }
      }

      Flow {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
          Rectangle {
            id: scaleBtn
            required property real modelData
            width: 38; height: 26; radius: 6
            color: Math.abs((panel.monitor ? panel.monitor.scale : -1) - modelData) < 0.01
                   ? panel.theme.accentPrimary
                   : (scaleMouse.containsMouse ? (panel.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : panel.theme.bgSurface)
            border.color: Math.abs((panel.monitor ? panel.monitor.scale : -1) - modelData) < 0.01 ? panel.theme.accentPrimary : panel.theme.bgBorder
            border.width: 1
            scale: scaleMouse.pressed ? 0.94 : (scaleMouse.containsMouse ? 1.04 : 1.0)

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            Text {
              anchors.centerIn: parent
              text: scaleBtn.modelData + "×"
              color: Math.abs((panel.monitor ? panel.monitor.scale : -1) - scaleBtn.modelData) < 0.01 ? panel.theme.bgBase : panel.theme.textPrimary
              font { pixelSize: 10; family: panel.font }
            }

            MouseArea {
              id: scaleMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.scaleSelected(scaleBtn.modelData)
            }
          }
        }
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Rotation section
      Text {
        text: "Rotation"
        color: panel.theme.textSecondary
        font { pixelSize: 11; family: panel.font }
      }

      Row {
        spacing: 4

        Repeater {
          model: [
            { t: 0, label: "0°",   icon: "󰍹" },
            { t: 1, label: "90°",  icon: "󰑧" },
            { t: 2, label: "180°", icon: "󱃨" },
            { t: 3, label: "270°", icon: "󰑥" },
          ]

          Rectangle {
            id: rotBtn
            required property var modelData
            width: 52; height: 26; radius: 6
            color: (panel.monitor ? panel.monitor.transform : -1) === modelData.t
                   ? panel.theme.accentPrimary
                   : (rotMouse.containsMouse ? (panel.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : panel.theme.bgSurface)
            border.color: (panel.monitor ? panel.monitor.transform : -1) === modelData.t ? panel.theme.accentPrimary : panel.theme.bgBorder
            border.width: 1
            scale: rotMouse.pressed ? 0.94 : (rotMouse.containsMouse ? 1.03 : 1.0)

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            Row {
              anchors.centerIn: parent
              spacing: 4
              Text {
                text: rotBtn.modelData.icon
                anchors.verticalCenter: parent.verticalCenter
                color: (panel.monitor ? panel.monitor.transform : -1) === rotBtn.modelData.t ? panel.theme.bgBase : panel.theme.textMuted
                font { pixelSize: 13; family: panel.font }
              }
              Text {
                text: rotBtn.modelData.label
                anchors.verticalCenter: parent.verticalCenter
                color: (panel.monitor ? panel.monitor.transform : -1) === rotBtn.modelData.t ? panel.theme.bgBase : panel.theme.textPrimary
                font { pixelSize: 10; family: panel.font }
              }
            }

            MouseArea {
              id: rotMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.transformChanged(rotBtn.modelData.t)
            }
          }
        }
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Mirror section
      Text {
        text: "Mirror of"
        color: panel.theme.textSecondary
        font { pixelSize: 11; family: panel.font }
      }

      // Mirror collapsed pill
      Rectangle {
        id: mirrorPill
        Layout.fillWidth: true
        height: 32
        radius: 8
        color: panel.theme.bgSurface
        border.color: panel.mirrorPickerOpen ? panel.theme.accentPrimary : panel.theme.bgBorder
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Row {
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          spacing: 0

          Text {
            text: (panel.monitor && panel.monitor.mirrorOf) ? panel.monitor.mirrorOf : "None"
            color: (panel.monitor && panel.monitor.mirrorOf) ? panel.theme.textPrimary : panel.theme.textMuted
            font { pixelSize: 12; family: panel.font }
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 20
            elide: Text.ElideRight
          }
          Text {
            text: panel.mirrorPickerOpen ? "▴" : "▾"
            color: panel.theme.textMuted
            font { pixelSize: 16; family: panel.font }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (panel.mirrorPickerOpen) {
              mirrorDropdown.close();
            } else {
              modeDropdown.close();
              mirrorDropdown.open();
            }
          }
        }
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Enable / Disable toggle
      Rectangle {
        id: enableBtn
        Layout.fillWidth: true
        height: 32
        radius: 8
        color: (!panel.monitor || panel.monitor.disabled)
               ? (enableMouse.containsMouse ? (panel.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : panel.theme.bgSurface)
               : (enableMouse.containsMouse ? (panel.theme.accentGreenHover ?? panel.theme.accentGreen) : panel.theme.accentGreen)
        border.color: (!panel.monitor || panel.monitor.disabled) ? panel.theme.bgBorder : panel.theme.accentGreen
        border.width: 1
        scale: enableMouse.pressed ? 0.97 : 1.0

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 100 } }

        Row {
          anchors.centerIn: parent
          spacing: 8
          Text {
            text: (!panel.monitor || panel.monitor.disabled) ? "Disabled" : "Enabled"
            anchors.verticalCenter: parent.verticalCenter
            color: (!panel.monitor || panel.monitor.disabled) ? panel.theme.textMuted : panel.theme.bgBase
            font { pixelSize: 12; bold: true; family: panel.font }
          }
        }

        MouseArea {
          id: enableMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (panel.monitor !== null) panel.enableToggled(panel.monitor.disabled);
          }
        }
      }

      // Bottom spacer
      Item { height: 8 }
    }
  }
}
