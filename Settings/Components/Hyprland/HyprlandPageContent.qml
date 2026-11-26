import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: mainCol
    width: parent.width
    spacing: 18

    /* Top Page Header */
    RowLayout {
        Layout.fillWidth: true

        ColumnLayout {
            spacing: 3
            Text {
                text: "Hyprland Settings"
                font.family: root.font
                font.pixelSize: Style.px(20)
                font.bold: true
                color: root.theme.textPrimary
            }
        }

        Item { Layout.fillWidth: true }
    }

    ParallelAnimation {
        id: subTabContentAnim
        NumberAnimation {
            target: subTabContentContainer
            property: "opacity"
            from: 0.35
            to: 1.0
            duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: subTabContentTranslate
            property: "y"
            from: 8
            to: 0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    /* Sub-Tab Navigation Bar */
    SubTabBar {
        currentIndex: root.currentSubTab
        tabs: [
            { idx: 0, icon: "󰖲", label: "General & Layout" },
            { idx: 1, icon: "󰏘", label: "Window Decoration" },
            { idx: 2, icon: "󰕮", label: "Window Rules" },
            { idx: 3, icon: "󰌒", label: "Gestures & Touchpad" },
            { idx: 4, icon: "󰒓", label: "Misc & Compositor" }
        ]
        onTabSelected: (idx) => {
            root.currentSubTab = idx;
            subTabContentAnim.restart();
        }
    }

    ColumnLayout {
        id: subTabContentContainer
        Layout.fillWidth: true
        spacing: 16
        transform: Translate { id: subTabContentTranslate; y: 0 }

    // TAB 0: GENERAL & LAYOUT
    HyprlandLiveWindowLayoutPreview {
        root: mainCol.root
    }

    // TAB 1: WINDOW DECORATION
    HyprlandWindowCornerRounding {
        root: mainCol.root
    }

    // TAB 2: WINDOW RULES
    HyprlandWindowRules {
        root: mainCol.root
    }

    // TAB 3: GESTURES & TOUCHPAD
    HyprlandTouchpadWorkspaceGestures {
        root: mainCol.root
    }

    // TAB 4: MISC & COMPOSITOR
    HyprlandDisplaySyncRefresh {
        root: mainCol.root
    }
}
}
