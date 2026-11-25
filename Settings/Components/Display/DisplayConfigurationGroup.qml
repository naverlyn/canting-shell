import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../MonitorManager"
import "../../../MonitorManager/Components"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    Layout.fillWidth: true
    spacing: 8
    visible: root.selectedMonitor !== null

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8

        Text {
            text: root.selectedMonitor
                ? ("Display Configuration  —  " + root.selectedMonitor.name)
                : "Display Configuration"
            font.family: root.font
            font.pixelSize: Style.px(13)
            font.bold: true
            color: root.theme.textSecondary
        }

        Text {
            visible: root.selectedMonitor !== null && (root.selectedMonitor.description || "") !== ""
            text: root.selectedMonitor ? ("·  " + root.selectedMonitor.description) : ""
            font.family: root.font
            font.pixelSize: Style.px(11)
            color: root.theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: configCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: configCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Display Identity & Enable Switch (Text-only, no icon badge) */
            DisplayIdentityRow {
                root: self.root
            }

            RowDivider {}

            /* Row 2: Resolution Expander Row */
            DisplayResolutionExpander {
                root: self.root
            }

            RowDivider {}

            /* Row 3: Refresh Rate Selector */
            DisplayRefreshRateRow {
                root: self.root
            }

            RowDivider {}

            /* Row 4: Scale Selector */
            DisplayScaleSelector {
                root: self.root
            }

            RowDivider {}

            /* Row 5: Orientation / Rotation (Segmented control) */
            DisplayOrientation {
                root: self.root
            }

            RowDivider { visible: root.editState.length > 1 }

            /* Row 6: Mirror Display Expander (visible when >1 monitor connected) */
            DisplayMirrorSelector {
                root: self.root
            }
        }
    }
}
