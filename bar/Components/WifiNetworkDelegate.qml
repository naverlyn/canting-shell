import QtQuick
import QtQuick.Layouts

Rectangle {
  id: netDelegate

  required property var modelData
  required property var theme
  required property color accent
  required property string font
  required property bool isExpanded
  required property bool isSaved
  required property bool isConnecting
  required property string connectingSsid
  required property bool autoConnect
  required property string passwordInput
  required property var signalIconFn

  signal toggleExpand(string ssid)
  signal toggleAutoConnect()
  signal passwordEdited(string pwd)
  signal connectRequested(string ssid, bool secured, string pwd)
  signal disconnectRequested(string ssid)

  readonly property bool needsPassword: modelData.secured && !modelData.active && !isSaved

  height: isExpanded ? (needsPassword ? 154 : 118) : 44
  radius: 10
  color: isExpanded
    ? Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.07)
    : (rowHov.hovered ? Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.045) : "transparent")
  border.color: isExpanded
    ? Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.10)
    : "transparent"
  border.width: 1
  clip: true
  Behavior on height { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
  Behavior on color { ColorAnimation { duration: 130 } }

  HoverHandler { id: rowHov }

  // Fluent short pill accent indicator on the left
  Rectangle {
    visible: netDelegate.isExpanded || netDelegate.modelData.active
    width: 3
    height: netDelegate.isExpanded ? 24 : 16
    y: netDelegate.isExpanded ? 12 : 14
    anchors.left: parent.left
    anchors.leftMargin: 3
    radius: 1.5
    color: netDelegate.accent
    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 12
    anchors.topMargin: 8
    anchors.bottomMargin: 10
    spacing: 8

    // Main network header row
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: 28

      RowLayout {
        anchors.fill: parent
        spacing: 12

        Text {
          text: netDelegate.signalIconFn(netDelegate.modelData.signal, netDelegate.modelData.secured)
          font.family: netDelegate.font
          font.pixelSize: 16
          color: netDelegate.modelData.active ? netDelegate.accent : netDelegate.theme.textPrimary
          Layout.preferredWidth: 20
          horizontalAlignment: Text.AlignHCenter
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1

          Text {
            text: netDelegate.modelData.ssid
            font.family: netDelegate.font
            font.pixelSize: 12
            font.bold: netDelegate.modelData.active || netDelegate.isExpanded
            color: netDelegate.theme.textPrimary
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          Text {
            visible: netDelegate.isExpanded || netDelegate.modelData.active
            text: {
              if (netDelegate.isConnecting && netDelegate.connectingSsid === netDelegate.modelData.ssid) return "Connecting...";
              if (netDelegate.modelData.active) return netDelegate.modelData.secured ? "Connected, secured" : "Connected, open";
              return netDelegate.modelData.secured ? (netDelegate.isSaved ? "Saved, secured" : "Secured") : "Open";
            }
            font.family: netDelegate.font
            font.pixelSize: 10
            color: netDelegate.modelData.active ? netDelegate.accent : netDelegate.theme.textSecondary
          }
        }

        Text {
          visible: !netDelegate.isExpanded
          text: netDelegate.modelData.signal + "%"
          font.family: netDelegate.font
          font.pixelSize: 10
          color: netDelegate.theme.textMuted
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: netDelegate.toggleExpand(netDelegate.modelData.ssid)
      }
    }

    // Expanded controls indented to align with SSID text (Windows 11 style)
    ColumnLayout {
      visible: netDelegate.isExpanded
      Layout.fillWidth: true
      Layout.leftMargin: 32
      spacing: 10

      // "Connect automatically" checkbox row
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
          width: 16; height: 16; radius: 4
          color: netDelegate.autoConnect ? netDelegate.accent : "transparent"
          border.color: netDelegate.autoConnect ? netDelegate.accent : Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.35)
          border.width: 1.5
          Behavior on color { ColorAnimation { duration: 120 } }

          Text {
            visible: netDelegate.autoConnect
            anchors.centerIn: parent
            text: "󰄬"
            font.family: netDelegate.font
            font.pixelSize: 12
            font.bold: true
            color: netDelegate.theme.bgBase
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: netDelegate.toggleAutoConnect()
          }
        }

        Text {
          text: "Connect automatically"
          font.family: netDelegate.font
          font.pixelSize: 11
          color: netDelegate.theme.textSecondary
          Layout.fillWidth: true

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: netDelegate.toggleAutoConnect()
          }
        }
      }

      // Password field when connecting to a new secured network
      Loader {
        active: netDelegate.isExpanded && netDelegate.needsPassword
        visible: active
        Layout.fillWidth: true
        Layout.preferredHeight: 28

        sourceComponent: Rectangle {
          radius: 6
          color: netDelegate.theme.bgBase
          border.color: pwdInput.activeFocus ? netDelegate.accent : netDelegate.theme.bgBorder
          border.width: 1

          TextInput {
            id: pwdInput
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            font.family: netDelegate.font
            font.pixelSize: 11
            color: netDelegate.theme.textPrimary
            echoMode: TextInput.Password
            selectByMouse: true
            onTextChanged: netDelegate.passwordEdited(text)
            onAccepted: netDelegate.connectRequested(netDelegate.modelData.ssid, netDelegate.modelData.secured, text)

            Text {
              visible: parent.text === "" && !parent.activeFocus
              anchors.verticalCenter: parent.verticalCenter
              text: "Enter network security key..."
              font.family: netDelegate.font
              font.pixelSize: 10
              color: netDelegate.theme.textMuted
            }
          }
        }
      }

      // Bottom-right Connect / Disconnect button
      RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }

        Rectangle {
          width: 124
          height: 28
          radius: 6
          color: netDelegate.modelData.active
            ? (actBtnHov.hovered ? Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.16) : Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.10))
            : (actBtnHov.hovered ? Qt.lighter(netDelegate.accent, 1.1) : netDelegate.accent)
          border.color: netDelegate.modelData.active
            ? Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.14)
            : "transparent"
          border.width: 1
          scale: actBtnMouse.pressed ? 0.96 : 1.0
          Behavior on scale { NumberAnimation { duration: 100 } }
          Behavior on color { ColorAnimation { duration: 120 } }
          HoverHandler { id: actBtnHov }

          Text {
            anchors.centerIn: parent
            text: (netDelegate.isConnecting && netDelegate.connectingSsid === netDelegate.modelData.ssid)
              ? "Working..."
              : (netDelegate.modelData.active ? "Disconnect" : "Connect")
            font.family: netDelegate.font
            font.pixelSize: 11
            font.bold: true
            color: netDelegate.modelData.active ? netDelegate.theme.textPrimary : netDelegate.theme.bgBase
          }

          MouseArea {
            id: actBtnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (netDelegate.modelData.active) {
                netDelegate.disconnectRequested(netDelegate.modelData.ssid);
              } else {
                netDelegate.connectRequested(netDelegate.modelData.ssid, netDelegate.modelData.secured, netDelegate.passwordInput);
              }
            }
          }
        }
      }
    }
  }
}
