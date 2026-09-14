import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
  id: root
  property var theme: Theme
  property string font: "Hack Nerd Font"
  property bool commandMode: false

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      launcherPanel.visible = !launcherPanel.visible
      if (launcherPanel.visible) {
        root.commandMode = false
        searchInput.text = ""
        commandInput.text = ""
        selectedIndex = 0
        searchInput.forceActiveFocus()
      }
    }
  }

  property int selectedIndex: 0

  // Runner process for executing Linux commands
  Process {
    id: cmdRunner
  }

  function runCommand(cmdText) {
    const trimmed = cmdText.trim();
    if (trimmed !== "") {
      cmdRunner.command = ["sh", "-c", trimmed];
      cmdRunner.running = true;
      launcherPanel.visible = false;
    }
  }

  ScriptModel {
    id: filteredApps
    objectProp: "id"
    values: {
      const all = [...DesktopEntries.applications.values];
      const q = searchInput.text.trim().toLowerCase();
      if (q === "") return all.sort((a, b) => a.name.localeCompare(b.name));
      return all.filter(d =>
        (d.name && d.name.toLowerCase().includes(q)) ||
        (d.genericName && d.genericName.toLowerCase().includes(q)) ||
        (d.keywords && d.keywords.some(k => k.toLowerCase().includes(q))) ||
        (d.categories && d.categories.some(c => c.toLowerCase().includes(q)))
      ).sort((a, b) => {
        const an = a.name.toLowerCase();
        const bn = b.name.toLowerCase();
        const aStarts = an.startsWith(q);
        const bStarts = bn.startsWith(q);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return an.localeCompare(bn);
      });
    }
  }

  function launchApp(entry) {
    if (entry) {
      entry.execute();
      launcherPanel.visible = false;
    }
  }

  PanelWindow {
    id: launcherPanel
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-launcher"

    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Dark overlay backdrop
    MouseArea {
      anchors.fill: parent
      onClicked: launcherPanel.visible = false

      Rectangle {
        anchors.fill: parent
        color: root.theme.bgOverlay
      }
    }

    // Centered launcher box
    Rectangle {
      id: launcherBox
      anchors.centerIn: parent
      width: 620
      height: 480
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1

      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Text {
            text: root.commandMode ? "  Execute Command" : "  Applications"
            color: root.theme.accentPrimary
            font.pixelSize: 14
            font.family: root.font
            font.bold: true

            Behavior on color { ColorAnimation { duration: 150 } }
          }

          Item { Layout.fillWidth: true }

          // Applications | Commands column
          Rectangle {
            id: modeToggle
            implicitWidth: modeRow.implicitWidth + 6
            implicitHeight: 26
            radius: 8
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
              id: modeRow
              anchors.fill: parent
              anchors.margins: 3
              spacing: 3

              // Applications tab
              Rectangle {
                Layout.fillHeight: true
                implicitWidth: appsLabel.implicitWidth + 20
                radius: 6
                color: !root.commandMode ? root.theme.bgSelected : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                  id: appsLabel
                  anchors.centerIn: parent
                  verticalAlignment: Text.AlignVCenter
                  horizontalAlignment: Text.AlignHCenter
                  text: "Applications"
                  color: !root.commandMode ? root.theme.accentPrimary : root.theme.textMuted
                  font.pixelSize: 11
                  font.family: root.font
                  font.bold: !root.commandMode

                  Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.commandMode = false;
                    searchInput.forceActiveFocus();
                  }
                }
              }

              // Commands tab
              Rectangle {
                Layout.fillHeight: true
                implicitWidth: cmdsLabel.implicitWidth + 20
                radius: 6
                color: root.commandMode ? root.theme.bgSelected : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                  id: cmdsLabel
                  anchors.centerIn: parent
                  verticalAlignment: Text.AlignVCenter
                  horizontalAlignment: Text.AlignHCenter
                  text: "Commands"
                  color: root.commandMode ? root.theme.accentPrimary : root.theme.textMuted
                  font.pixelSize: 11
                  font.family: root.font
                  font.bold: root.commandMode

                  Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.commandMode = true;
                    commandInput.forceActiveFocus();
                  }
                }
              }
            }
          }
        }

        // Search bar
        Rectangle {
          Layout.fillWidth: true
          height: 36
          radius: 8
          visible: !root.commandMode
          color: root.theme.bgSurface
          border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
          border.width: 1

          Behavior on color { ColorAnimation { duration: 150 } }
          Behavior on border.color { ColorAnimation { duration: 150 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: ""
              color: root.theme.textMuted
              font.pixelSize: 13
              font.family: root.font
              Layout.alignment: Qt.AlignVCenter

              Behavior on color { ColorAnimation { duration: 150 } }
            }

            Item {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              implicitHeight: searchInput.implicitHeight

              TextInput {
                id: searchInput
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: root.theme.textPrimary
                font.pixelSize: 13
                font.family: root.font
                clip: true
                selectByMouse: true
                Accessible.role: Accessible.EditableText
                Accessible.name: "Search applications"

                onTextChanged: {
                  root.selectedIndex = 0
                  resultsList.positionViewAtIndex(0, ListView.Beginning)
                }

                Keys.onEscapePressed: launcherPanel.visible = false

                Keys.onPressed: event => {
                  if (event.key === Qt.Key_Down) {
                    event.accepted = true;
                    root.selectedIndex = Math.min(root.selectedIndex + 1, resultsList.count - 1);
                    resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                  } else if (event.key === Qt.Key_Up) {
                    event.accepted = true;
                    root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                    resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                  } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    if (root.selectedIndex >= 0 && root.selectedIndex < filteredApps.values.length) {
                      const entry = filteredApps.values[root.selectedIndex];
                      if (entry) root.launchApp(entry);
                    }
                  } else if (event.key === Qt.Key_Tab) {
                    event.accepted = true;
                    root.selectedIndex = Math.min(root.selectedIndex + 1, resultsList.count - 1);
                    resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                  }
                }
              }

              Text {
                text: "Search applications..."
                color: root.theme.textMuted
                font.pixelSize: 13
                font.family: root.font
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text === ""

                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }
          }
        }

        // Command Bar
        Rectangle {
          Layout.fillWidth: true
          height: 36
          radius: 8
          visible: root.commandMode
          color: root.theme.bgSurface
          border.color: commandInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
          border.width: 1

          Behavior on color { ColorAnimation { duration: 150 } }
          Behavior on border.color { ColorAnimation { duration: 150 } }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: "$"
              color: root.theme.accentPrimary
              font.pixelSize: 13
              font.family: root.font
              font.bold: true
              Layout.alignment: Qt.AlignVCenter

              Behavior on color { ColorAnimation { duration: 150 } }
            }

            Item {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              implicitHeight: commandInput.implicitHeight

              TextInput {
                id: commandInput
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: root.theme.textPrimary
                font.pixelSize: 13
                font.family: root.font
                clip: true
                selectByMouse: true
                Accessible.role: Accessible.EditableText
                Accessible.name: "Execute shell command"

                Keys.onEscapePressed: launcherPanel.visible = false

                Keys.onPressed: event => {
                  if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    root.runCommand(commandInput.text);
                  }
                }
              }

              Text {
                text: "Type shell command (e.g. htop, kitty, reboot)..."
                color: root.theme.textMuted
                font.pixelSize: 13
                font.family: root.font
                anchors.verticalCenter: parent.verticalCenter
                visible: commandInput.text === ""

                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }
          }
        }

        // App list
        ListView {
          id: resultsList
          Layout.fillWidth: true
          Layout.fillHeight: true
          visible: !root.commandMode
          model: filteredApps
          clip: true
          spacing: 2
          boundsBehavior: Flickable.StopAtBounds
          currentIndex: root.selectedIndex
          highlightMoveDuration: 150
          highlightMoveVelocity: -1

          highlight: Rectangle {
            radius: 8
            color: root.theme.bgSelected
            visible: resultsList.count > 0 && root.selectedIndex >= 0

            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
              width: 3
              height: 24
              radius: 2
              color: root.theme.accentPrimary
              anchors.left: parent.left
              anchors.leftMargin: 2
              anchors.verticalCenter: parent.verticalCenter

              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }

          delegate: Rectangle {
            id: delegateRoot
            required property var modelData
            required property int index

            Accessible.role: Accessible.Button
            Accessible.name: (modelData.name ?? "Application") + (modelData.genericName ? " - " + modelData.genericName : "")

            width: resultsList.width
            height: 44
            radius: 8
            color: hoverArea.containsMouse && root.selectedIndex !== index ? root.theme.bgHover : "transparent"

            Behavior on color { ColorAnimation { duration: 100 } }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              spacing: 12

              // App icon
              Item {
                width: 24
                height: 24
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                  anchors.fill: parent
                  source: Quickshell.iconPath(delegateRoot.modelData.icon ?? "", true)
                  visible: (delegateRoot.modelData.icon ?? "") !== ""
                }

                // Fallback icon
                Text {
                  anchors.centerIn: parent
                  text: ""
                  color: root.theme.accentPrimary
                  font.pixelSize: 18
                  font.family: root.font
                  visible: (delegateRoot.modelData.icon ?? "") === ""

                  Behavior on color { ColorAnimation { duration: 150 } }
                }
              }

              // App info
              ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                  text: delegateRoot.modelData.name ?? ""
                  color: root.selectedIndex === delegateRoot.index ? root.theme.textPrimary : root.theme.textSecondary
                  font.pixelSize: 13
                  font.family: root.font
                  font.bold: root.selectedIndex === delegateRoot.index
                  elide: Text.ElideRight
                  Layout.fillWidth: true

                  Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                  text: delegateRoot.modelData.genericName ?? delegateRoot.modelData.comment ?? ""
                  color: root.theme.textMuted
                  font.pixelSize: 11
                  font.family: root.font
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  visible: text !== ""

                  Behavior on color { ColorAnimation { duration: 150 } }
                }
              }
            }

            MouseArea {
              id: hoverArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.launchApp(delegateRoot.modelData)
              onEntered: root.selectedIndex = delegateRoot.index
            }
          }

          // Empty state
          Text {
            anchors.centerIn: parent
            text: "No applications found"
            color: root.theme.textMuted
            font.pixelSize: 13
            font.family: root.font
            visible: resultsList.count === 0 && searchInput.text !== ""

            Behavior on color { ColorAnimation { duration: 150 } }
          }
        }

        // Commands hint
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true
          visible: root.commandMode

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
              text: "Enter a command and press Return to run"
              color: root.theme.textMuted
              font.pixelSize: 13
              font.family: root.font
              Layout.alignment: Qt.AlignHCenter

              Behavior on color { ColorAnimation { duration: 150 } }
            }
          }
        }

        // Footer
        RowLayout {
          Layout.fillWidth: true
          spacing: 16

          Row {
            spacing: 4
            visible: !root.commandMode
            Rectangle {
              width: hintUp.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
              Behavior on color { ColorAnimation { duration: 150 } }
              Text { id: hintUp; anchors.centerIn: parent; text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
            }
            Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Row {
            spacing: 4
            Rectangle {
              width: hintEnter.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
              Behavior on color { ColorAnimation { duration: 150 } }
              Text { id: hintEnter; anchors.centerIn: parent; text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
            }
            Text { text: root.commandMode ? "execute" : "launch"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Row {
            spacing: 4
            Rectangle {
              width: hintEsc.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
              Behavior on color { ColorAnimation { duration: 150 } }
              Text { id: hintEsc; anchors.centerIn: parent; text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
            }
            Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Item { Layout.fillWidth: true }
        }
      }
    }
  }
}