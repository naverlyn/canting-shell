import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"

ColumnLayout {
    required property var root
    property alias animationStudioPanelInstRef: animationStudioPanelInst
    id: mainCol
    x: 8
    width: parent.width - 16
    spacing: 18

    // Page Header (Title on Left, Buttons pushed firmly to the Far Right)
    AnimationPageHeader {
        root: mainCol.root
    }

    // Custom Animation Studio Panel (Expandable)
    AnimationStudioPanel {
        id: animationStudioPanelInst
        root: mainCol.root
    }

    // 1. Master Enable / Disable Card (Clean Text-Only AdwActionRow style)
    AnimationMasterToggleCard {
        root: mainCol.root
    }

    // 2. Preset Selector Section
    AnimationPresetsPanel {
        root: mainCol.root
    }

    // 4. Active Compositor Curves & Rules Summary
    AnimationActiveCurvesSummary {
        root: mainCol.root
    }
}
