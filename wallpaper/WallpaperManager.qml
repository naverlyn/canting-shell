import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "./Components"

Scope {
  id: root
  property var theme: Theme
  property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"

  property string searchText: ""
  property string previewPath: ""
  property bool browsingFolders: false
  property bool panelVisible: false

  IpcHandler {
    target: "wallpaper"

    function toggle() {
      root.panelVisible = !root.panelVisible;
      if (root.panelVisible) {
        root.searchText = "";
        root.previewPath = "";
        root.browsingFolders = false;
        if (WallpaperService.wallpapers.length === 0) WallpaperService.rescan();
      } else {
        Qt.callLater(() => gc());
      }
    }

    function addFolder(path: string) {
      WallpaperService.addDirectory(path);
    }

    function removeFolder(path: string) {
      WallpaperService.removeDirectory(path);
    }

    function rescan() {
      WallpaperService.rescan();
    }
  }

  property var filteredWallpapers: {
    if (!root.panelVisible) return [];
    const q = searchText.toLowerCase().trim();
    let list = WallpaperService.wallpapers || [];
    if (q !== "") {
      list = list.filter(p => {
        const name = p.split("/").pop().toLowerCase();
        return name.includes(q);
      });
    }
    const curA = WallpaperService.wallpaperA;
    const curB = WallpaperService.wallpaperB;
    const curMain = WallpaperService.currentWallpaper;
    const tops = [];
    if (curA && list.includes(curA)) tops.push(curA);
    if (curB && list.includes(curB) && !tops.includes(curB)) tops.push(curB);
    if (curMain && list.includes(curMain) && !tops.includes(curMain)) tops.push(curMain);
    if (tops.length > 0) {
      list = tops.concat(list.filter(p => !tops.includes(p)));
    }
    return list;
  }

  Loader {
    active: root.panelVisible
    sourceComponent: Component {
  PanelWindow {
    id: wallpaperPanel
    visible: true
    focusable: true
    color: "transparent"

    property bool closing: false

    function requestClose() {
      if (wallpaperPanel.closing) return;
      wallpaperPanel.closing = true;
      openAnim.stop();
      closeAnim.start();
    }

    Component.onCompleted: {
      openAnim.start();
      Qt.callLater(() => pickerGridSection.searchInput.forceActiveFocus());
    }

    onVisibleChanged: {
      if (!visible) {
        root.previewPath = "";
        root.browsingFolders = false;
        root.panelVisible = false;
        Qt.callLater(() => gc());
      }
    }

    ParallelAnimation {
      id: openAnim
      NumberAnimation { target: wallpaperCard; property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
      NumberAnimation { target: wallpaperCard; property: "scale"; from: 0.96; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
      id: closeAnim
      NumberAnimation { target: wallpaperCard; property: "opacity"; to: 0.0; duration: 110; easing.type: Easing.InCubic }
      NumberAnimation { target: wallpaperCard; property: "scale"; to: 0.97; duration: 110; easing.type: Easing.InCubic }
      onFinished: wallpaperPanel.visible = false
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-wallpaper"

    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Undimmed transparent backdrop
    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (root.previewPath !== "") {
          root.previewPath = "";
        } else {
          wallpaperPanel.requestClose();
        }
      }
    }

    // Main wallpaper box
    Rectangle {
      id: wallpaperCard
      anchors.centerIn: parent
      width: 840
      height: 640
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1
      clip: true
      opacity: 0.0
      scale: 0.96

      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }

      MouseArea {
        anchors.fill: parent
        onClicked: event => event.accepted = true
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12


        // Header
        WallpaperHeader {
          hostRoot: root
          searchInputRef: pickerGridSection.searchInput
        }

        /* View 1: Folder browser */
        WallpaperFolderBrowser {
          hostRoot: root
          hostPanel: wallpaperPanel
        }

        /* View 2: Wallpaper picker grid */
        WallpaperPickerGrid {
          id: pickerGridSection
          hostRoot: root
          hostPanel: wallpaperPanel
        }

        // Footer
        WallpaperFooter {
          hostRoot: root
        }
      }
    }

    // Preview overlay
    WallpaperPreviewOverlay {
      hostRoot: root
    }
  }
    }
  }
}
