import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
  id: root

  required property var theme
  required property string font
  property color accent: theme.accentPrimary
  property var appShortcuts: []

  signal requestCollapse()

  function findDesktopEntry(appId) {
    if (!appId) return null;
    const target = String(appId).trim().toLowerCase();
    if (!target) return null;
    const entries = (DesktopEntries && DesktopEntries.applications && DesktopEntries.applications.values)
      ? DesktopEntries.applications.values
      : [];
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i];
      if (!e) continue;
      const eid = String(e.id || "").toLowerCase();
      const ename = String(e.name || "").toLowerCase();
      if (eid === target || ename === target) return e;
    }
    return DesktopEntries.heuristicLookup(appId) || null;
  }

  readonly property var resolvedEntries: {
    const ids = Array.isArray(root.appShortcuts) ? root.appShortcuts : [];
    const out = [];
    for (let i = 0; i < ids.length; i++) {
      const e = root.findDesktopEntry(ids[i]);
      if (e) out.push(e);
    }
    return out;
  }

  implicitHeight: contentCol.implicitHeight
  height: implicitHeight

  ColumnLayout {
    id: contentCol
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 8

    // Empty state when no apps are pinned yet
    Rectangle {
      visible: root.resolvedEntries.length === 0
      Layout.fillWidth: true
      Layout.preferredHeight: 68
      radius: 12
      color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)

      Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "No pinned apps"
          font.family: root.font
          font.pixelSize: 12
          font.bold: true
          color: root.theme.textPrimary
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Pin favorite apps in Bar Settings → Layout & Panels"
          font.family: root.font
          font.pixelSize: 10
          color: root.theme.textSecondary
        }
      }
    }

    // Squircle App Shortcut Dock
    Flow {
      visible: root.resolvedEntries.length > 0
      Layout.alignment: Qt.AlignHCenter
      Layout.maximumWidth: parent.width
      Layout.topMargin: 4
      Layout.bottomMargin: 4
      spacing: 12

      Repeater {
        model: root.resolvedEntries
        delegate: Item {
          id: appTile
          required property var modelData
          readonly property string iconName: String(modelData.icon || "")
          readonly property string iconPath: iconName !== "" ? (Quickshell.iconPath(iconName, true) || "") : ""
          readonly property bool isFileIcon: iconPath.startsWith("file://") || iconPath.startsWith("/")

          width: 54
          height: 54

          Rectangle {
            id: squircle
            anchors.fill: parent
            radius: 14
            color: appHover.hovered
              ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
              : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.07)
            border.color: appHover.hovered
              ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.50)
              : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08)
            border.width: 1
            scale: appMouse.pressed ? 0.90 : (appHover.hovered ? 1.08 : 1.0)

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

            IconImage {
              id: themeAppIcon
              anchors.centerIn: parent
              implicitSize: 34
              source: (!appTile.isFileIcon && appTile.iconPath !== "") ? appTile.iconPath : ""
              visible: source !== "" && status === Image.Ready
            }

            Image {
              id: fileAppIcon
              anchors.centerIn: parent
              width: 34
              height: 34
              source: appTile.isFileIcon ? (appTile.iconPath.startsWith("/") ? ("file://" + appTile.iconPath) : appTile.iconPath) : ""
              sourceSize.width: 68
              sourceSize.height: 68
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              visible: source !== "" && status === Image.Ready && themeAppIcon.status !== Image.Ready
            }

            Text {
              anchors.centerIn: parent
              visible: themeAppIcon.status !== Image.Ready && fileAppIcon.status !== Image.Ready
              text: String(appTile.modelData.name || "A").slice(0, 1).toUpperCase()
              font.family: root.font
              font.pixelSize: 18
              font.bold: true
              color: root.accent
            }
          }

          HoverHandler { id: appHover }

          MouseArea {
            id: appMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              try {
                appTile.modelData.execute();
              } catch (e) {}
              root.requestCollapse();
            }
          }
        }
      }
    }
  }
}
