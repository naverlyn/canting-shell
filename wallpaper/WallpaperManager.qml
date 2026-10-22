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
  property string font: "Hack Nerd Font"

  property string searchText: ""
  property string previewPath: ""
  property bool browsingFolders: false

  IpcHandler {
    target: "wallpaper"

    function toggle() {
      wallpaperPanel.visible = !wallpaperPanel.visible;
      if (wallpaperPanel.visible) {
        root.searchText = "";
        root.previewPath = "";
        root.browsingFolders = false;
        pickerGridSection.searchInput.forceActiveFocus();
        if (WallpaperService.wallpapers.length === 0) WallpaperService.rescan();
      }
    }

    function addFolder(path) {
      WallpaperService.addDirectory(path);
    }

    function removeFolder(path) {
      WallpaperService.removeDirectory(path);
    }

    function rescan() {
      WallpaperService.rescan();
    }
  }

  property var filteredWallpapers: {
    if (!wallpaperPanel.visible) return [];
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

  PanelWindow {
    id: wallpaperPanel
    visible: false
    focusable: true
    color: "transparent"

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

    // Dark overlay backdrop
    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (root.previewPath !== "") {
          root.previewPath = "";
        } else {
          wallpaperPanel.visible = false;
        }
      }

      Rectangle {
        anchors.fill: parent
        color: root.theme.bgOverlay
      }
    }

    // Main wallpaper box
    Rectangle {
      anchors.centerIn: parent
      width: 840
      height: 640
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1

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
