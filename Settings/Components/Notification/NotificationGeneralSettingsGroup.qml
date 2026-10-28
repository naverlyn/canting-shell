import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../notifications"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    title: "General Behavior & Queue Limits"
    subtitle: "Configure Do Not Disturb, auto-dismiss timing, popup stack limits, and card dimensions"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Do Not Disturb"
        desc: "Pause banner popups and alert notifications"
        checked: root.isDnd
        onToggled: (val) => {
            NotificationService.doNotDisturb = val;
            root.showToast(val ? "Do Not Disturb enabled" : "Do Not Disturb disabled");
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Pause Timeout on Hover"
        desc: "Keep notification toast open while hovering with the mouse cursor"
        checked: NotificationService.pauseOnHover
        onToggled: (val) => NotificationService.setPauseOnHover(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Auto-Dismiss Timeout"
        desc: "Default duration before notification popups automatically close"
        value: NotificationService.defaultTimeout
        minVal: 2000
        maxVal: 15000
        step: 500
        unit: "ms"
        presets: [
            { label: "3s", val: 3000 },
            { label: "5s", val: 5000 },
            { label: "8s", val: 8000 },
            { label: "10s", val: 10000 }
        ]
        onValueModified: (val) => NotificationService.setDefaultTimeout(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Max Visible Toasts"
        desc: "Maximum number of concurrent notification popups stacked on screen"
        value: NotificationService.maxVisibleToasts
        minVal: 1
        maxVal: 10
        step: 1
        unit: ""
        presets: [
            { label: "3", val: 3 },
            { label: "5", val: 5 },
            { label: "7", val: 7 },
            { label: "10", val: 10 }
        ]
        onValueModified: (val) => NotificationService.setMaxVisibleToasts(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Toast Card Width"
        desc: "Horizontal width of desktop notification popups in pixels"
        value: NotificationService.toastWidth
        minVal: 280
        maxVal: 500
        step: 10
        unit: "px"
        presets: [
            { label: "320px", val: 320 },
            { label: "360px", val: 360 },
            { label: "400px", val: 400 },
            { label: "440px", val: 440 }
        ]
        onValueModified: (val) => NotificationService.setToastWidth(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Stack Spacing"
        desc: "Vertical gap between multiple active notification toasts"
        value: NotificationService.cardSpacing
        minVal: 4
        maxVal: 24
        step: 2
        unit: "px"
        presets: [
            { label: "6px", val: 6 },
            { label: "8px", val: 8 },
            { label: "12px", val: 12 },
            { label: "16px", val: 16 }
        ]
        onValueModified: (val) => NotificationService.setCardSpacing(val)
    }
}
