import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
  id: root

  required property var theme
  required property string font
  required property bool commandMode
  required property string prefixMode
  required property string searchQuery
  required property string commandQuery
  required property int selectedIndex
  required property bool userExpanded
  required property bool isExpanded
  required property var appsModel
  required property var appUsage
  required property var smartResults
  required property var commandHistory
  required property string copyFeedbackText

  signal overlayClosed()
  signal searchQueryUpdated(string text)
  signal commandQueryUpdated(string text)
  signal modeSwitchRequested(bool toCommandMode)
  signal expandRequested()
  signal collapseRequested()
  signal selectionRequested(int index)
  signal appLaunched(var entry)
  signal smartItemActivated(var item)
  signal commandExecuteRequested(string cmd)

  function focusActiveInput() {
    searchBar.focusActiveInput();
  }

  visible: true
  focusable: true
  color: "transparent"

  property bool closing: false

  function requestClose() {
    if (root.closing) return;
    root.closing = true;
    openAnim.stop();
    closeAnim.start();
  }

  Component.onCompleted: {
    openAnim.start();
    Qt.callLater(() => searchBar.initAndFocus());
  }

  onVisibleChanged: {
    if (!visible) {
      root.overlayClosed();
    }
  }

  ParallelAnimation {
    id: openAnim
    NumberAnimation { target: launcherBox; property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    NumberAnimation { target: launcherBox; property: "scale"; from: 0.96; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
  }

  ParallelAnimation {
    id: closeAnim
    NumberAnimation { target: launcherBox; property: "opacity"; to: 0.0; duration: 110; easing.type: Easing.InCubic }
    NumberAnimation { target: launcherBox; property: "scale"; to: 0.97; duration: 110; easing.type: Easing.InCubic }
    onFinished: root.visible = false
  }

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

  // Undimmed transparent backdrop (dismisses on click outside)
  MouseArea {
    anchors.fill: parent
    onClicked: root.requestClose()
  }

  // Centered Spotlight Runner Box
  Rectangle {
    id: launcherBox
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.max(80, (root.height - height) / 2 - (root.isExpanded ? 0 : 60))
    width: AppLauncherConfig.spotlightWidth
    height: root.isExpanded ? AppLauncherConfig.spotlightHeight : 60
    radius: 16
    color: root.theme.bgBase
    border.color: root.theme.bgBorder
    border.width: 1
    clip: true
    opacity: 0.0
    scale: 0.96

    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    // Absorb clicks inside the card so it doesn't dismiss
    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      // 1. TOP SPOTLIGHT SEARCH BAR
      SpotlightSearchBar {
        id: searchBar
        theme: root.theme
        font: root.font
        commandMode: root.commandMode
        prefixMode: root.prefixMode
        searchQuery: root.searchQuery
        commandQuery: root.commandQuery
        selectedIndex: root.selectedIndex
        activeListCount: (root.prefixMode === "apps") ? resultsList.count : smartResultsList.count
        userExpanded: root.userExpanded
        commandHistory: root.commandHistory
        copyFeedbackText: root.copyFeedbackText

        onSearchQueryUpdated: text => {
          root.searchQueryUpdated(text);
          if (root.prefixMode === "apps") {
            if (resultsList.count > 0) resultsList.scrollToIndex(0, ListView.Beginning);
          } else if (smartResultsList.count > 0) {
            smartResultsList.scrollToIndex(0, ListView.Beginning);
          }
        }
        onCommandQueryUpdated: text => root.commandQueryUpdated(text)
        onModeSwitchRequested: toCommandMode => root.modeSwitchRequested(toCommandMode)
        onExpandRequested: root.expandRequested()
        onCollapseRequested: root.collapseRequested()
        onSelectionRequested: index => {
          root.selectionRequested(index);
          if (root.prefixMode === "apps") {
            resultsList.scrollToIndex(index, ListView.Contain);
          } else {
            smartResultsList.scrollToIndex(index, ListView.Contain);
          }
        }
        onActivateRequested: {
          if (root.prefixMode === "apps") {
            if (resultsList.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < resultsList.count) {
              root.appLaunched(root.appsModel.values[root.selectedIndex]);
            }
          } else if (smartResultsList.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < smartResultsList.count) {
            root.smartItemActivated(root.smartResults[root.selectedIndex]);
          }
        }
        onCommandExecuteRequested: cmd => root.commandExecuteRequested(cmd)
        onCloseRequested: root.visible = false
      }

      // Thin subtle divider
      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: root.theme.bgBorder
        visible: root.isExpanded
      }

      // 2. RESULTS / COMMAND RUNNER AREA
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.isExpanded
        clip: true

        AppResultsList {
          id: resultsList
          anchors.fill: parent
          theme: root.theme
          font: root.font
          appsModel: root.appsModel
          appUsage: root.appUsage
          selectedIndex: root.selectedIndex
          searchQuery: root.searchQuery
          opacity: (!root.commandMode && root.prefixMode === "apps") ? 1.0 : 0.0
          visible: opacity > 0.01

          onAppSelected: index => root.selectionRequested(index)
          onAppLaunched: entry => root.appLaunched(entry)
        }

        SmartResultsList {
          id: smartResultsList
          anchors.fill: parent
          theme: root.theme
          font: root.font
          prefixMode: root.prefixMode
          smartResults: root.smartResults
          selectedIndex: root.selectedIndex
          opacity: (!root.commandMode && root.prefixMode !== "apps") ? 1.0 : 0.0
          visible: opacity > 0.01

          onItemSelected: index => root.selectionRequested(index)
          onItemActivated: item => root.smartItemActivated(item)
        }
      }

      // 3. FOOTER HINTS
      SpotlightFooter {
        theme: root.theme
        font: root.font
        commandMode: root.commandMode
        isExpanded: root.isExpanded
      }
    }
  }
}
