import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."

Item {
  id: root

  required property var barContainer
  property var theme
  property string font: "Lato Nerd Font"

  readonly property bool isVert: barContainer.isVert
  readonly property var menus: GlobalMenuService.menus

  implicitHeight: isVert ? 28 : (barContainer.hidePill ? barContainer.height : 24)
  height: implicitHeight
  implicitWidth: isVert ? barContainer.vertPillWidth : Math.max(36, horizRow.implicitWidth + 10)
  width: implicitWidth

  property Item activeAnchorItem: null
  property int expandedSubmenuId: -1

  onActiveAnchorItemChanged: {
    root.expandedSubmenuId = -1;
    if (dropdownPopup.visible && root.activeAnchorItem) {
      dropdownPopup.reposition();
    }
  }

  // Auto-dismiss dropdown when mouse leaves both the menu bar and the popup
  Timer {
    id: autoDismissTimer
    interval: 420
    repeat: false
    running: GlobalMenuService.isMenuOpen && !barHover.hovered && !popupHover.hovered
    onTriggered: {
      if (!barHover.hovered && !popupHover.hovered) {
        GlobalMenuService.closeMenu();
        root.activeAnchorItem = null;
      }
    }
  }

  Rectangle {
    id: menuContainer
    anchors.fill: parent
    radius: root.barContainer.pillRadius
    color: root.barContainer.wBg("globalMenu", false)
    border.color: root.barContainer.wBorder("globalMenu")
    border.width: root.barContainer.hasCustomColor("globalMenu") ? 1 : 0
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    HoverHandler { id: barHover }

    // --- Vertical Bar Layout ---
    Item {
      id: vertLayout
      visible: root.isVert
      anchors.fill: parent

      scale: vertMouse.pressed ? 0.90 : 1.0
      Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

      HoverHandler { id: vertHover }

      Text {
        anchors.centerIn: parent
        text: "󰍜"
        font.family: root.font
        font.pixelSize: 13
        color: root.barContainer.wAccent("globalMenu", root.theme.accentPrimary)
      }

      MouseArea {
        id: vertMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (GlobalMenuService.isMenuOpen) {
            GlobalMenuService.closeMenu();
            root.activeAnchorItem = null;
          } else if (root.menus.length > 0) {
            root.activeAnchorItem = menuContainer;
            GlobalMenuService.activeTopMenuIndex = 0;
          }
        }
      }
    }

    // --- Horizontal Bar Layout ---
    Row {
      id: horizRow
      visible: !root.isVert
      anchors.centerIn: parent
      spacing: 2

      // Optional prefix glyph
      Item {
        visible: BarConfig.showGlobalMenuIcon
        width: 18
        height: 20
        anchors.verticalCenter: parent.verticalCenter

        Text {
          anchors.centerIn: parent
          text: "󰍜"
          font.family: root.font
          font.pixelSize: 11
          color: root.barContainer.wAccent("globalMenu", root.theme.accentPrimary)
          opacity: 0.85
        }
      }

      Repeater {
        id: menuRepeater
        model: root.menus

        delegate: Rectangle {
          id: menuBtn
          required property var modelData
          required property int index

          readonly property bool isActive: GlobalMenuService.activeTopMenuIndex === menuBtn.index && root.activeAnchorItem !== null
          readonly property bool isHovered: btnHover.hovered

          implicitWidth: btnText.implicitWidth + 14
          implicitHeight: 20
          width: implicitWidth
          height: implicitHeight
          anchors.verticalCenter: parent.verticalCenter
          radius: Math.max(4, root.barContainer.pillRadius - 3)
          color: isActive
            ? (root.barContainer.hasCustomColor("globalMenu")
                ? root.barContainer.wBg("globalMenu", true)
                : root.theme.bgSelected)
            : (isHovered ? root.theme.bgHover : "transparent")

          scale: btnMouse.pressed ? 0.94 : 1.0
          Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 130 } }

          Text {
            id: btnText
            anchors.centerIn: parent
            text: menuBtn.modelData.label || ""
            font.family: root.font
            font.pixelSize: 11
            font.bold: menuBtn.isActive
            color: menuBtn.isActive
              ? root.barContainer.wAccent("globalMenu", root.theme.accentPrimary)
              : (menuBtn.isHovered
                  ? root.theme.textPrimary
                  : (root.barContainer.hasCustomColor("globalMenu")
                      ? root.barContainer.wAccent("globalMenu", root.theme.textPrimary)
                      : root.theme.textSecondary))
            Behavior on color { ColorAnimation { duration: 120 } }
          }

          // Active indicator underline
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: menuBtn.isActive ? (parent.width - 10) : 0
            height: 2
            radius: 1
            color: root.barContainer.wAccent("globalMenu", root.theme.accentPrimary)
            opacity: menuBtn.isActive ? 1.0 : 0.0
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }

          HoverHandler { id: btnHover }

          MouseArea {
            id: btnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: {
              if (GlobalMenuService.activeTopMenuIndex === menuBtn.index && root.activeAnchorItem === menuBtn) {
                GlobalMenuService.closeMenu();
                root.activeAnchorItem = null;
              } else {
                root.activeAnchorItem = menuBtn;
                GlobalMenuService.activeTopMenuIndex = menuBtn.index;
              }
            }

            onEntered: {
              if (GlobalMenuService.isMenuOpen && (GlobalMenuService.activeTopMenuIndex !== menuBtn.index || root.activeAnchorItem !== menuBtn)) {
                root.activeAnchorItem = menuBtn;
                GlobalMenuService.activeTopMenuIndex = menuBtn.index;
              }
            }
          }
        }
      }
    }
  }

  // --- Submenu Dropdown Popup ---
  PopupWindow {
    id: dropdownPopup
    property var menuRoot: root

    function closeMenu() {
      if (menuRoot) menuRoot.activeAnchorItem = null;
    }

    readonly property bool shouldBeVisible: GlobalMenuService.isMenuOpen && root.activeAnchorItem !== null
    visible: shouldBeVisible || popupCard.opacity > 0.01
    color: "transparent"
    implicitWidth: popupCard.implicitWidth + 12
    implicitHeight: popupCard.implicitHeight + 12

    anchor.window: root.activeAnchorItem ? root.activeAnchorItem.QsWindow.window : (root.barContainer ? root.barContainer.QsWindow.window : null)
    anchor.edges: {
      if (root.barContainer.barPos === "bottom") return Edges.Top;
      if (root.barContainer.barPos === "left") return Edges.Right;
      if (root.barContainer.barPos === "right") return Edges.Left;
      return Edges.Bottom;
    }
    anchor.gravity: {
      if (root.barContainer.barPos === "bottom") return Edges.Top;
      if (root.barContainer.barPos === "left") return Edges.Right;
      if (root.barContainer.barPos === "right") return Edges.Left;
      return Edges.Bottom;
    }
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip

    anchor.onAnchoring: {
      const win = dropdownPopup.anchor.window;
      if (!win || !root.activeAnchorItem) return;
      const widgetRect = win.contentItem.mapFromItem(
        root.activeAnchorItem, 0, 0,
        root.activeAnchorItem.width, root.activeAnchorItem.height
      );
      if (root.barContainer) {
        const bRect = win.contentItem.mapFromItem(
          root.barContainer, 0, 0,
          root.barContainer.width, root.barContainer.height
        );
        if (root.barContainer.barPos === "top" || root.barContainer.barPos === "bottom") {
          dropdownPopup.anchor.rect = Qt.rect(widgetRect.x, bRect.y, widgetRect.width, bRect.height);
        } else {
          dropdownPopup.anchor.rect = Qt.rect(bRect.x, widgetRect.y, bRect.width, widgetRect.height);
        }
      } else {
        dropdownPopup.anchor.rect = widgetRect;
      }
    }

    readonly property var currentTopMenu: (GlobalMenuService.activeTopMenuIndex >= 0 && GlobalMenuService.activeTopMenuIndex < root.menus.length)
      ? root.menus[GlobalMenuService.activeTopMenuIndex]
      : null

    readonly property var currentItems: currentTopMenu && currentTopMenu.children ? currentTopMenu.children : []

    Rectangle {
      id: popupCard
      implicitWidth: Math.max(210, Math.min(320, itemsCol.implicitWidth + 20))
      implicitHeight: Math.min(420, itemsCol.implicitHeight + 14)
      width: implicitWidth
      height: implicitHeight
      radius: 10
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1

      opacity: dropdownPopup.shouldBeVisible ? 1.0 : 0.0
      scale: dropdownPopup.shouldBeVisible ? 1.0 : 0.95
      transformOrigin: {
        if (root.barContainer.barPos === "bottom") return Item.Bottom;
        if (root.barContainer.barPos === "left") return Item.Left;
        if (root.barContainer.barPos === "right") return Item.Right;
        return Item.Top;
      }
      x: root.barContainer.barPos === "left"
        ? (dropdownPopup.shouldBeVisible ? 6 : 0)
        : (root.barContainer.barPos === "right" ? (dropdownPopup.shouldBeVisible ? 6 : 12) : 6)
      y: root.barContainer.barPos === "top"
        ? (dropdownPopup.shouldBeVisible ? 6 : 0)
        : (root.barContainer.barPos === "bottom" ? (dropdownPopup.shouldBeVisible ? 6 : 12) : 6)

      Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
      Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      HoverHandler { id: popupHover }

      ScrollView {
        id: menuScroll
        anchors.fill: parent
        anchors.margins: 6
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: itemsCol.implicitHeight > 400 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

        ColumnLayout {
          id: itemsCol
          width: Math.max(196, popupCard.implicitWidth - 12)
          spacing: 2

          // Vertical Bar: Header switcher for top-level menus
          RowLayout {
            visible: root.isVert && root.menus.length > 1
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            spacing: 4

            Repeater {
              model: root.menus
              delegate: Rectangle {
                id: vertTabBtn
                required property var modelData
                required property int index
                readonly property bool isCur: GlobalMenuService.activeTopMenuIndex === vertTabBtn.index

                Layout.fillWidth: true
                height: 22
                radius: 5
                color: isCur ? root.theme.bgSelected : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: vertTabBtn.modelData.label || ""
                  font.family: root.font
                  font.pixelSize: 10
                  font.bold: vertTabBtn.isCur
                  color: vertTabBtn.isCur
                    ? root.barContainer.wAccent("globalMenu", root.theme.accentPrimary)
                    : root.theme.textSecondary
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: GlobalMenuService.activeTopMenuIndex = vertTabBtn.index
                }
              }
            }
          }

          Repeater {
            model: dropdownPopup.currentItems

            delegate: ColumnLayout {
              id: itemDelegate
              required property var modelData
              required property int index

              readonly property bool isSep: Boolean(itemDelegate.modelData.is_separator)
              readonly property bool isItemEnabled: !isSep && (itemDelegate.modelData.enabled !== false)
              readonly property bool hasSub: Boolean(itemDelegate.modelData.children && itemDelegate.modelData.children.length > 0)
              readonly property bool subExpanded: hasSub && dropdownPopup.menuRoot && dropdownPopup.menuRoot.expandedSubmenuId === itemDelegate.modelData.id
              property bool isClicked: false

              Timer {
                id: clickActionTimer
                interval: 120
                repeat: false
                onTriggered: {
                  GlobalMenuService.triggerAction(itemDelegate.modelData);
                  dropdownPopup.closeMenu();
                  itemDelegate.isClicked = false;
                }
              }

              Layout.fillWidth: true
              spacing: 1

              // Separator divider
              Item {
                visible: itemDelegate.isSep
                Layout.fillWidth: true
                implicitHeight: 7

                Rectangle {
                  anchors.centerIn: parent
                  width: parent.width - 10
                  height: 1
                  color: root.theme.bgBorder
                }
              }

              // Clickable Menu Row
              Rectangle {
                id: itemBg
                visible: !itemDelegate.isSep
                Layout.fillWidth: true
                implicitHeight: 26
                radius: 6
                color: itemDelegate.isClicked
                  ? (root.barContainer.hasCustomColor("globalMenu")
                      ? root.barContainer.wBg("globalMenu", true)
                      : root.theme.bgSelected)
                  : ((rowHover.hovered || itemDelegate.subExpanded) && itemDelegate.isItemEnabled
                      ? root.theme.bgHover
                      : "transparent")
                Behavior on color { ColorAnimation { duration: 110 } }

                scale: itemDelegate.isClicked ? 0.93 : (itemMouse.pressed ? 0.96 : 1.0)
                Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                // Selection flash overlay
                Rectangle {
                  id: clickFlash
                  anchors.fill: parent
                  radius: parent.radius
                  color: root.barContainer.wAccent("globalMenu", root.theme.accentPrimary)
                  opacity: itemDelegate.isClicked ? 0.35 : 0.0
                  scale: itemDelegate.isClicked ? 1.0 : 0.85
                  Behavior on opacity { NumberAnimation { duration: 110 } }
                  Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                }

                HoverHandler { id: rowHover }

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 8

                  transform: Translate {
                    x: (rowHover.hovered && itemDelegate.isItemEnabled) ? 3 : 0
                    Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                  }

                  // Item Icon
                  Text {
                    visible: Boolean(itemDelegate.modelData.icon && itemDelegate.modelData.icon !== "")
                    text: itemDelegate.modelData.icon || ""
                    font.family: root.font
                    font.pixelSize: 12
                    color: (itemDelegate.isClicked || (rowHover.hovered && itemDelegate.isItemEnabled))
                      ? root.theme.textPrimary
                      : root.barContainer.wAccent("globalMenu", root.theme.accentPrimary)
                    scale: itemDelegate.isClicked ? 1.25 : ((rowHover.hovered && itemDelegate.isItemEnabled) ? 1.15 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Layout.preferredWidth: 16
                  }

                  // Checkmark / State indicator
                  Text {
                    visible: Boolean(itemDelegate.modelData.toggle_type && itemDelegate.modelData.toggle_type !== "")
                    text: (itemDelegate.modelData.toggle_state === 1) ? "✓" : ""
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.barContainer.wAccent("globalMenu", root.theme.accentPrimary)
                    Layout.preferredWidth: 12
                  }

                  // Menu Label
                  Text {
                    Layout.fillWidth: true
                    text: itemDelegate.modelData.label || ""
                    font.family: root.font
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    color: !itemDelegate.isItemEnabled
                      ? root.theme.textMuted
                      : (itemDelegate.isClicked || rowHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                    Behavior on color { ColorAnimation { duration: 100 } }
                  }

                  // Shortcut badge
                  Text {
                    visible: Boolean(itemDelegate.modelData.shortcut && itemDelegate.modelData.shortcut !== "")
                    text: itemDelegate.modelData.shortcut || ""
                    font.family: root.font
                    font.pixelSize: 10
                    color: (itemDelegate.isClicked || (rowHover.hovered && itemDelegate.isItemEnabled))
                      ? root.theme.textSecondary
                      : root.theme.textMuted
                    Behavior on color { ColorAnimation { duration: 100 } }
                  }

                  // Submenu indicator
                  Text {
                    visible: itemDelegate.hasSub
                    text: itemDelegate.subExpanded ? "󰅀" : "󰅂"
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textMuted
                  }
                }

                MouseArea {
                  id: itemMouse
                  anchors.fill: parent
                  enabled: itemDelegate.isItemEnabled && !itemDelegate.isClicked
                  cursorShape: itemDelegate.isItemEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                  onClicked: {
                    if (itemDelegate.hasSub) {
                      if (dropdownPopup.menuRoot) {
                        dropdownPopup.menuRoot.expandedSubmenuId = itemDelegate.subExpanded ? -1 : itemDelegate.modelData.id;
                      }
                    } else {
                      itemDelegate.isClicked = true;
                      clickActionTimer.start();
                    }
                  }
                }
              }

              // Inline Expandable Submenu Items
              ColumnLayout {
                visible: itemDelegate.subExpanded
                Layout.fillWidth: true
                Layout.leftMargin: 12
                spacing: 1

                Repeater {
                  model: itemDelegate.hasSub ? itemDelegate.modelData.children : []
                  delegate: Rectangle {
                    id: subItemRow
                    required property var modelData
                    readonly property bool isSubSep: Boolean(subItemRow.modelData.is_separator)
                    readonly property bool isSubEnabled: !isSubSep && (subItemRow.modelData.enabled !== false)
                    property bool isSubClicked: false

                    Timer {
                      id: subClickActionTimer
                      interval: 120
                      repeat: false
                      onTriggered: {
                        GlobalMenuService.triggerAction(subItemRow.modelData);
                        dropdownPopup.closeMenu();
                        subItemRow.isSubClicked = false;
                      }
                    }

                    visible: !isSubSep
                    Layout.fillWidth: true
                    implicitHeight: 24
                    radius: 5
                    color: subItemRow.isSubClicked
                      ? root.theme.bgSelected
                      : (subHover.hovered && isSubEnabled ? root.theme.bgHover : "transparent")
                    Behavior on color { ColorAnimation { duration: 110 } }

                    scale: subItemRow.isSubClicked ? 0.93 : (subMouse.pressed ? 0.96 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                    Rectangle {
                      anchors.fill: parent
                      radius: parent.radius
                      color: root.barContainer.wAccent("globalMenu", root.theme.accentPrimary)
                      opacity: subItemRow.isSubClicked ? 0.35 : 0.0
                      scale: subItemRow.isSubClicked ? 1.0 : 0.85
                      Behavior on opacity { NumberAnimation { duration: 110 } }
                      Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    }

                    HoverHandler { id: subHover }

                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 8
                      anchors.rightMargin: 8
                      spacing: 6

                      transform: Translate {
                        x: (subHover.hovered && isSubEnabled) ? 3 : 0
                        Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                      }

                      Text {
                        Layout.fillWidth: true
                        text: subItemRow.modelData.label || ""
                        font.family: root.font
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        color: !subItemRow.isSubEnabled
                          ? root.theme.textMuted
                          : (subHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                        Behavior on color { ColorAnimation { duration: 100 } }
                      }

                      Text {
                        visible: Boolean(subItemRow.modelData.shortcut && subItemRow.modelData.shortcut !== "")
                        text: subItemRow.modelData.shortcut || ""
                        font.family: root.font
                        font.pixelSize: 10
                        color: (subHover.hovered && isSubEnabled) ? root.theme.textSecondary : root.theme.textMuted
                        Behavior on color { ColorAnimation { duration: 100 } }
                      }
                    }

                    MouseArea {
                      id: subMouse
                      anchors.fill: parent
                      enabled: subItemRow.isSubEnabled && !subItemRow.isSubClicked
                      cursorShape: subItemRow.isSubEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                      onClicked: {
                        subItemRow.isSubClicked = true;
                        subClickActionTimer.start();
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
