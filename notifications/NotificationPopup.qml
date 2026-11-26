import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../bar"
import "Components"
import "../ThemeSwitcher"

Scope {
    id: root
    property var theme: Theme
    property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"

    IpcHandler {
        target: "notifications"

        function dismiss_all() {
            NotificationService.dismissAll();
        }

        function dnd_toggle() {
            NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
        }

        function dnd_off() {
            NotificationService.doNotDisturb = false;
        }

        function set_position(pos: string) {
            NotificationService.setToastPosition(pos);
        }

        function test_toast() {
            NotificationService.sendCustomNotification({});
        }
    }

    Variants {
        model: (Quickshell.screens || []).filter(s => s && s.name && s.name !== "")

        PanelWindow {
            id: notifWindow
            required property var modelData
            screen: modelData
            readonly property bool suppressedByDynamicIsland: {
                void BarConfig.panelsRevision;
                void BarConfig.barVisible;
                const scrName = (modelData && modelData.name) ? String(modelData.name) : "";
                return BarConfig.shouldSuppressToastOnScreen(scrName);
            }
            visible: NotificationService.notifications.length > 0 && !suppressedByDynamicIsland
            focusable: false
            color: "transparent"

            readonly property string toastPos: NotificationService.toastPosition || "top-right"
            readonly property bool isTop: toastPos.indexOf("top") === 0
            readonly property bool isBottom: toastPos.indexOf("bottom") === 0
            readonly property bool isLeft: toastPos.indexOf("left") !== -1
            readonly property bool isRight: toastPos.indexOf("right") !== -1
            readonly property bool isCenter: toastPos.indexOf("center") !== -1

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-notifications"

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0

            anchors {
                top: notifWindow.isTop
                bottom: notifWindow.isBottom
                left: notifWindow.isLeft
                right: notifWindow.isRight
            }

            margins {
                top: notifWindow.isTop ? NotificationService.toastMarginY : 0
                bottom: notifWindow.isBottom ? NotificationService.toastMarginY : 0
                left: notifWindow.isLeft ? NotificationService.toastMarginX : 0
                right: notifWindow.isRight ? NotificationService.toastMarginX : 0
            }

            implicitWidth: NotificationService.toastWidth + 20
            implicitHeight: notifColumn.implicitHeight + 20

            ColumnLayout {
                id: notifColumn
                width: NotificationService.toastWidth
                x: notifWindow.isLeft ? 10 : (notifWindow.isRight ? parent.width - width - 10 : Math.round((parent.width - width) / 2))
                y: notifWindow.isBottom ? Math.max(0, parent.height - implicitHeight - 10) : 10
                spacing: NotificationService.cardSpacing

                Repeater {
                    model: ScriptModel {
                        values: notifWindow.suppressedByDynamicIsland ? [] : NotificationService.notifications
                        objectProp: "seqId"
                    }

                    ToastCard {
                        theme: root.theme
                        font: root.font
                        isLeft: notifWindow.isLeft
                        isRight: notifWindow.isRight
                        isCenter: notifWindow.isCenter
                        isBottom: notifWindow.isBottom
                    }
                }
            }
        }
    }
}
