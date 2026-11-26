import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../notifications"
import "../../notifications/NotificationPresentation.js" as NotifPres
import ".."

Item {
  id: root

  required property var theme
  required property string font
  property color accent: theme.accentPrimary

  readonly property var historyList: NotificationService.history || []
  readonly property bool isDnd: NotificationService.doNotDisturb

  property var expandedGroups: ({})
  property string expandedNotifId: ""
  property bool clearingAll: false
  property string clearingGroup: ""

  Timer {
    id: clearAllTimer
    interval: 210
    repeat: false
    onTriggered: {
      NotificationService.clearHistory();
      root.expandedGroups = ({});
      root.expandedNotifId = "";
      root.clearingAll = false;
    }
  }

  Timer {
    id: clearGroupTimer
    interval: 210
    repeat: false
    onTriggered: {
      const grp = root.clearingGroup;
      root.clearingGroup = "";
      if (grp) {
        const copy = Object.assign({}, root.expandedGroups || {});
        delete copy[grp];
        root.expandedGroups = copy;
        NotificationService.dismissHistoryByApp(grp);
      }
    }
  }

  function isGroupExpanded(appKey) {
    return expandedGroups && expandedGroups[appKey] === true;
  }

  function toggleGroup(appKey) {
    const copy = Object.assign({}, expandedGroups || {});
    if (copy[appKey]) delete copy[appKey];
    else copy[appKey] = true;
    expandedGroups = copy;
  }

  function toggleExpanded(nid) {
    const key = String(nid || "");
    expandedNotifId = (expandedNotifId === key) ? "" : key;
  }

  readonly property var notifGroups: NotifPres.groupHistoryByApp(root.historyList, 20)

  implicitHeight: notifCol.implicitHeight
  height: implicitHeight

  ColumnLayout {
    id: notifCol
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 8

    // Header bar: count + DND toggle + Clear All
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: "Notifications" + (root.historyList.length > 0 ? (" (" + root.historyList.length + ")") : "")
        font.family: root.font
        font.pixelSize: 12
        font.bold: true
        color: root.theme.textPrimary
        Layout.fillWidth: true
      }

      // DND Pill
      Rectangle {
        Layout.preferredWidth: dndRow.implicitWidth + 16
        Layout.preferredHeight: 24
        radius: 12
        color: root.isDnd
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, dndHover.hovered ? 0.30 : 0.22)
          : (dndHover.hovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.13) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06))
        border.color: root.isDnd
          ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
          : (dndHover.hovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.16) : "transparent")
        border.width: 1
        scale: dndMouse.pressed ? 0.91 : (dndHover.hovered ? 1.04 : 1.0)

        Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        HoverHandler { id: dndHover }

        Row {
          id: dndRow
          anchors.centerIn: parent
          spacing: 5
          Text {
            id: dndIcon
            text: root.isDnd ? "󰂛" : "󰂚"
            font.family: root.font
            font.pixelSize: 11
            color: root.isDnd ? root.accent : (dndHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
            Behavior on color { ColorAnimation { duration: 140 } }

            SequentialAnimation {
              id: dndIconPop
              NumberAnimation { target: dndIcon; property: "scale"; to: 1.28; duration: 90; easing.type: Easing.OutQuad }
              NumberAnimation { target: dndIcon; property: "scale"; to: 1.0; duration: 160; easing.type: Easing.OutBack }
            }
          }
          Text {
            text: root.isDnd ? "DND On" : "DND"
            font.family: root.font
            font.pixelSize: 10
            font.bold: root.isDnd
            color: root.isDnd ? root.accent : (dndHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
            Behavior on color { ColorAnimation { duration: 140 } }
          }
        }

        MouseArea {
          id: dndMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
            dndIconPop.restart();
          }
        }
      }

      // Clear All button
      Rectangle {
        readonly property bool hasItems: root.historyList.length > 0
        visible: opacity > 0.01
        opacity: hasItems ? 1.0 : 0.0
        Layout.preferredWidth: hasItems ? (clearTxt.implicitWidth + 16) : 0
        Layout.preferredHeight: 24
        radius: 12
        color: clearHover.hovered
          ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.24)
          : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
        border.color: clearHover.hovered
          ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.45)
          : "transparent"
        border.width: 1
        scale: clearMouse.pressed ? 0.91 : (clearHover.hovered ? 1.04 : 1.0)
        clip: true

        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        HoverHandler { id: clearHover }

        Text {
          id: clearTxt
          anchors.centerIn: parent
          text: "Clear"
          font.family: root.font
          font.pixelSize: 10
          font.bold: true
          color: clearHover.hovered ? root.theme.accentRed : root.theme.textSecondary
          Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
          id: clearMouse
          anchors.fill: parent
          enabled: parent.hasItems && !root.clearingAll
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.clearingAll = true;
            clearAllTimer.restart();
          }
        }
      }
    }

    // Empty State
    Rectangle {
      visible: root.historyList.length === 0
      Layout.fillWidth: true
      Layout.preferredHeight: 76
      radius: 10
      color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)

      Text {
        anchors.centerIn: parent
        text: root.isDnd ? "Do Not Disturb is active" : "All caught up — no notifications"
        font.family: root.font
        font.pixelSize: 11
        color: root.theme.textSecondary
      }
    }

    // Grouped Notification Stack List
    Flickable {
      id: histFlick
      visible: root.historyList.length > 0
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(250, histCol.implicitHeight)
      contentHeight: histCol.implicitHeight
      contentWidth: width
      clip: true
      interactive: contentHeight > height + 2
      boundsBehavior: Flickable.StopAtBounds

      Behavior on Layout.preferredHeight {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
      }

      ScrollBar.vertical: ScrollBar {
        policy: histFlick.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        width: 3
        contentItem: Rectangle {
          radius: 1.5
          color: root.theme.bgBorder
        }
      }

      ColumnLayout {
        id: histCol
        width: histFlick.interactive ? (histFlick.width - 6) : histFlick.width
        spacing: 8

        Repeater {
          model: root.notifGroups
          delegate: ColumnLayout {
            id: groupBlock
            required property var modelData
            required property int index

            readonly property string appName: modelData.appName
            readonly property var items: modelData.items || []
            readonly property bool isMulti: items.length > 1
            readonly property bool isGroupOpen: isMulti && root.isGroupExpanded(appName)
            readonly property bool isCollapsedStack: isMulti && !isGroupOpen

            Layout.fillWidth: true
            spacing: 0

            // Minimal inline Collapse / Clear bar shown ONLY when a multi-card stack is expanded
            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: groupBlock.isGroupOpen ? groupHeaderRow.implicitHeight : 0
              Layout.bottomMargin: groupBlock.isGroupOpen ? 6 : 0
              opacity: groupBlock.isGroupOpen ? 1.0 : 0.0
              clip: true

              Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
              Behavior on Layout.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

              RowLayout {
                id: groupHeaderRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 6

                Text {
                  text: groupBlock.appName + " (" + groupBlock.items.length + ")"
                  font.family: root.font
                  font.pixelSize: 10
                  font.bold: true
                  color: root.theme.textSecondary
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Rectangle {
                  Layout.preferredWidth: colTxt.implicitWidth + 12
                  Layout.preferredHeight: 20
                  radius: 10
                  color: colHov.hovered ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16) : "transparent"
                  scale: colMs.pressed ? 0.92 : 1.0
                  Behavior on color { ColorAnimation { duration: 120 } }
                  Behavior on scale { NumberAnimation { duration: 100 } }
                  HoverHandler { id: colHov }

                  Text {
                    id: colTxt
                    anchors.centerIn: parent
                    text: "Collapse"
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: true
                    color: root.accent
                  }

                  MouseArea {
                    id: colMs
                    anchors.fill: parent
                    enabled: groupBlock.isGroupOpen
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleGroup(groupBlock.appName)
                  }
                }

                Rectangle {
                  Layout.preferredWidth: grpClrTxt.implicitWidth + 12
                  Layout.preferredHeight: 20
                  radius: 10
                  color: grpClrHov.hovered ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) : "transparent"
                  scale: grpClrMs.pressed ? 0.92 : 1.0
                  Behavior on color { ColorAnimation { duration: 120 } }
                  Behavior on scale { NumberAnimation { duration: 100 } }
                  HoverHandler { id: grpClrHov }

                  Text {
                    id: grpClrTxt
                    anchors.centerIn: parent
                    text: "Clear"
                    font.family: root.font
                    font.pixelSize: 10
                    color: grpClrHov.hovered ? root.theme.accentRed : root.theme.textMuted
                    Behavior on color { ColorAnimation { duration: 120 } }
                  }

                  MouseArea {
                    id: grpClrMs
                    anchors.fill: parent
                    enabled: groupBlock.isGroupOpen && root.clearingGroup === ""
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.clearingGroup = groupBlock.appName;
                      clearGroupTimer.restart();
                    }
                  }
                }
              }
            }

            Repeater {
              model: groupBlock.items
              delegate: DynamicIslandNotifCard {
                groupIndex: groupBlock.index
                groupAppName: groupBlock.appName
                groupSize: groupBlock.items.length
                isCollapsedStack: groupBlock.isCollapsedStack
                expandedNotifId: root.expandedNotifId
                isClearing: root.clearingAll || root.clearingGroup === groupBlock.appName
                theme: root.theme
                font: root.font
                accent: root.accent
                onRequestToggleGroup: (name) => root.toggleGroup(name)
                onRequestToggleExpanded: (nid) => root.toggleExpanded(nid)
              }
            }
          }
        }
      }
    }
  }
}
