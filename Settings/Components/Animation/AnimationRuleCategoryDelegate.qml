import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"

Rectangle {
    required property var root
    required property var modelData
    id: catGroupCard
    property string catName: modelData
    readonly property bool matchesFilter: root.studioCategoryFilter === "All" || root.studioCategoryFilter === catName
    visible: matchesFilter
    Layout.fillWidth: true
    radius: 0
    color: "transparent"
    border.width: 0
    implicitHeight: visible ? (catCol.implicitHeight + (root.studioCategoryFilter === "All" ? 8 : 0)) : 0

    ColumnLayout {
        id: catCol
        anchors.fill: parent
        spacing: 8

        // Category Header (Visible when viewing All)
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 2
            spacing: 8
            visible: root.studioCategoryFilter === "All"

            Text {
                text: catGroupCard.catName.toUpperCase()
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.accentPrimary
                Layout.leftMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            }
        }

        // Rules in this category
        Repeater {
            model: root.getRulesForCategory(catGroupCard.catName)

            Rectangle {
                id: ruleRowCard
                property var ruleItem: modelData
                property bool localExpanded: false
                readonly property bool isExpanded: root.expandAllRules ? true : localExpanded

                Layout.fillWidth: true
                radius: 12
                color: ruleRowCard.ruleItem.enabled ? root.theme.bgSurface : Qt.rgba(0, 0, 0, 0.15)
                border.color: isExpanded && ruleRowCard.ruleItem.enabled
                    ? root.theme.accentPrimary
                    : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1
                implicitHeight: ruleRowCol.implicitHeight + 24
                clip: true

                Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 160 } }
                Behavior on color { ColorAnimation { duration: 160 } }

                ColumnLayout {
                    id: ruleRowCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Top row: Title, Target tag, Description, and Actions
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Left: Clickable title/desc area that toggles expansion
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: titleCol.implicitHeight

                            ColumnLayout {
                                id: titleCol
                                anchors.fill: parent
                                spacing: 3

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: ruleRowCard.ruleItem.title || ruleRowCard.ruleItem.target
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: ruleRowCard.ruleItem.enabled ? root.theme.textPrimary : root.theme.textMuted
                                    }

                                    Rectangle {
                                        height: 18
                                        implicitWidth: targetTagText.implicitWidth + 10
                                        radius: 4
                                        color: Qt.rgba(1, 1, 1, 0.06)
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1

                                        Text {
                                            id: targetTagText
                                            anchors.centerIn: parent
                                            text: ruleRowCard.ruleItem.target
                                            font.family: "monospace"
                                            font.pixelSize: 10
                                            color: root.theme.textSecondary
                                        }
                                    }
                                }

                                Text {
                                    text: ruleRowCard.ruleItem.desc || ""
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                    visible: text !== ""
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: ruleRowCard.ruleItem.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (ruleRowCard.ruleItem.enabled) {
                                        ruleRowCard.localExpanded = !ruleRowCard.isExpanded;
                                    }
                                }
                            }
                        }

                        // Right: Summary badge, Preview, Toggle Switch, Expand Button
                        RowLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignVCenter

                            // Summary Badge (When enabled & collapsed)
                            Rectangle {
                                visible: ruleRowCard.ruleItem.enabled && !ruleRowCard.isExpanded
                                height: 26
                                implicitWidth: summaryBadgeText.implicitWidth + 16
                                radius: 6
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                Text {
                                    id: summaryBadgeText
                                    anchors.centerIn: parent
                                    text: {
                                        const c = ruleRowCard.ruleItem.curve || "default";
                                        const sp = ruleRowCard.ruleItem.speed + " (" + (ruleRowCard.ruleItem.speed * 100) + "ms)";
                                        const st = (ruleRowCard.ruleItem.style && ruleRowCard.ruleItem.style !== "") ? (" • " + ruleRowCard.ruleItem.style) : "";
                                        return c + " • " + sp + st;
                                    }
                                    font.family: root.font
                                    font.pixelSize: 10
                                    color: root.theme.textSecondary
                                }
                            }

                            // Quick Preview Button (Styled matching DisplaySettings buttons)
                            Rectangle {
                                visible: ruleRowCard.ruleItem.enabled
                                height: 28
                                implicitWidth: rPrevText.implicitWidth + 20
                                radius: 7
                                color: rPrevHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
                                border.color: rPrevHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: rPrevHover }

                                Text {
                                    id: rPrevText
                                    anchors.centerIn: parent
                                    text: "Preview"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: rPrevHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const tgt = ruleRowCard.ruleItem.target;
                                        if (tgt.indexOf("workspace") !== -1) root.previewMode = "workspaces";
                                        else if (tgt.indexOf("layer") !== -1) root.previewMode = "layersIn";
                                        else if (tgt === "windowsOut") root.previewMode = "windowsOut";
                                        else root.previewMode = "windowsIn";
                                        root.triggerPreview();
                                    }
                                }
                            }

                            // Standard Animated Toggle Switch (Matches SettingToggleRow)
                            Rectangle {
                                id: toggleSwitch
                                width: 44
                                height: 24
                                radius: 12
                                color: ruleRowCard.ruleItem.enabled ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: 160 } }

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: ruleRowCard.ruleItem.enabled ? parent.width - width - 3 : 3
                                    color: ruleRowCard.ruleItem.enabled ? "#ffffff" : root.theme.textPrimary

                                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.updateRuleField(ruleRowCard.ruleItem.target, "enabled", !ruleRowCard.ruleItem.enabled);
                                        root.showStatus(ruleRowCard.ruleItem.title + ": " + (!ruleRowCard.ruleItem.enabled ? "Enabled" : "Disabled"));
                                    }
                                }
                            }

                            // Expand / Collapse Chevron Button
                            Rectangle {
                                visible: ruleRowCard.ruleItem.enabled
                                height: 28
                                width: 28
                                radius: 14
                                color: expChevronHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"

                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: expChevronHover }

                                Text {
                                    id: chevronGlyph
                                    anchors.centerIn: parent
                                    text: "▾"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    color: ruleRowCard.isExpanded ? root.theme.accentPrimary : root.theme.textSecondary

                                    transform: Rotation {
                                        origin.x: chevronGlyph.width / 2
                                        origin.y: chevronGlyph.height / 2
                                        angle: ruleRowCard.isExpanded ? 180 : 0
                                        Behavior on angle { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ruleRowCard.localExpanded = !ruleRowCard.isExpanded
                                }
                            }
                        }
                    }

                    // Expandable Settings Body (Matching SettingSliderRow style)
                    ColumnLayout {
                        visible: ruleRowCard.ruleItem.enabled && ruleRowCard.isExpanded
                        Layout.fillWidth: true
                        spacing: 12
                        Layout.topMargin: 2

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        }

                        // 1. Easing Curve Row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            spacing: 12

                            ColumnLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 150
                                Layout.fillWidth: false

                                Text {
                                    text: "Easing Curve"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }

                                Text {
                                    text: "Bézier velocity profile"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Segmented Curve Track with Sliding Pill
                            Rectangle {
                                id: curveTrack
                                readonly property var curveList: root.studioBeziers || []
                                readonly property int activeIdx: {
                                    for (let i = 0; i < curveList.length; i++) {
                                        if (curveList[i].name === ruleRowCard.ruleItem.curve) return i;
                                    }
                                    return -1;
                                }
                                readonly property int count: curveList.length
                                implicitWidth: Math.min(ruleRowCol.width - 170, count * 90 + 6 + (count - 1) * 3)
                                width: implicitWidth
                                Layout.preferredWidth: implicitWidth
                                Layout.preferredHeight: 32
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                readonly property real cellWidth: count > 0 ? ((width - 6 - (count - 1) * 3) / count) : 0

                                /* Sliding Selection Pill */
                                Rectangle {
                                    visible: curveTrack.activeIdx >= 0
                                    y: 3
                                    height: parent.height - 6
                                    width: curveTrack.cellWidth
                                    x: 3 + Math.max(0, curveTrack.activeIdx) * (curveTrack.cellWidth + 3)
                                    radius: 5
                                    color: root.theme.bgSelected
                                    border.color: root.theme.accentPrimary
                                    border.width: 1

                                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Repeater {
                                        model: curveTrack.curveList
                                        delegate: Rectangle {
                                            id: cBtn
                                            required property var modelData
                                            required property int index
                                            readonly property bool isSel: curveTrack.activeIdx === cBtn.index

                                            Layout.preferredWidth: curveTrack.cellWidth
                                            Layout.minimumWidth: 0
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: !isSel && cHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: cHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: cBtn.modelData.name
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: cBtn.isSel
                                                color: cBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.updateRuleField(ruleRowCard.ruleItem.target, "curve", cBtn.modelData.name)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        }

                        // 2. Speed Factor Row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            spacing: 12

                            ColumnLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 150
                                Layout.fillWidth: false

                                Text {
                                    text: "Speed Factor"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }

                                Text {
                                    text: (ruleRowCard.ruleItem.speed * 100) + "ms" + (ruleRowCard.ruleItem.speed <= 2 ? " (Snappy)" : ruleRowCard.ruleItem.speed >= 8 ? " (Cinematic)" : " (Balanced)")
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.accentPrimary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Segmented Speed Track with Sliding Pill
                            Rectangle {
                                id: speedTrack
                                readonly property var speedList: ruleRowCard.ruleItem.target === "borderangle"
                                    ? [5, 10, 20, 30, 45, 60]
                                    : [1, 2, 3, 4, 5, 6, 8, 10]
                                readonly property int activeIdx: {
                                    const val = Number(ruleRowCard.ruleItem.speed);
                                    for (let i = 0; i < speedList.length; i++) {
                                        if (Number(speedList[i]) === val) return i;
                                    }
                                    return -1;
                                }
                                readonly property int count: speedList.length
                                implicitWidth: Math.min(ruleRowCol.width - 170, count * 44 + 6 + (count - 1) * 3)
                                width: implicitWidth
                                Layout.preferredWidth: implicitWidth
                                Layout.preferredHeight: 32
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                readonly property real cellWidth: count > 0 ? ((width - 6 - (count - 1) * 3) / count) : 0

                                /* Sliding Selection Pill */
                                Rectangle {
                                    visible: speedTrack.activeIdx >= 0
                                    y: 3
                                    height: parent.height - 6
                                    width: speedTrack.cellWidth
                                    x: 3 + Math.max(0, speedTrack.activeIdx) * (speedTrack.cellWidth + 3)
                                    radius: 5
                                    color: root.theme.bgSelected
                                    border.color: root.theme.accentPrimary
                                    border.width: 1

                                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Repeater {
                                        model: speedTrack.speedList
                                        delegate: Rectangle {
                                            id: spBtn
                                            required property var modelData
                                            required property int index
                                            readonly property bool isSel: speedTrack.activeIdx === spBtn.index

                                            Layout.preferredWidth: speedTrack.cellWidth
                                            Layout.minimumWidth: 0
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: !isSel && spHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: spHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: String(spBtn.modelData)
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: spBtn.isSel
                                                color: spBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.updateRuleField(ruleRowCard.ruleItem.target, "speed", Number(spBtn.modelData))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Motion Style Row (if applicable)
                        ColumnLayout {
                            visible: Boolean(ruleRowCard.ruleItem.styles && ruleRowCard.ruleItem.styles.length > 0 && ruleRowCard.ruleItem.styles[0] !== "")
                            Layout.fillWidth: true
                            spacing: 12

                            // Divider
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 150
                                    Layout.fillWidth: false

                                    Text {
                                        text: "Motion Style"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Compositor visual effect"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Segmented Style Track with Sliding Pill
                                Rectangle {
                                    id: styleTrack
                                    readonly property var styleList: (ruleRowCard.ruleItem.styles || []).filter(s => s !== "")
                                    readonly property int activeIdx: styleList.indexOf(ruleRowCard.ruleItem.style)
                                    readonly property int count: styleList.length
                                    implicitWidth: Math.min(ruleRowCol.width - 170, count * 96 + 6 + (count - 1) * 3)
                                    width: implicitWidth
                                    Layout.preferredWidth: implicitWidth
                                    Layout.preferredHeight: 32
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                    readonly property real cellWidth: count > 0 ? ((width - 6 - (count - 1) * 3) / count) : 0

                                    /* Sliding Selection Pill */
                                    Rectangle {
                                        visible: styleTrack.activeIdx >= 0
                                        y: 3
                                        height: parent.height - 6
                                        width: styleTrack.cellWidth
                                        x: 3 + Math.max(0, styleTrack.activeIdx) * (styleTrack.cellWidth + 3)
                                        radius: 5
                                        color: root.theme.bgSelected
                                        border.color: root.theme.accentPrimary
                                        border.width: 1

                                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 3

                                        Repeater {
                                            model: styleTrack.styleList
                                            delegate: Rectangle {
                                                id: stBtn
                                                required property var modelData
                                                required property int index
                                                readonly property bool isSel: styleTrack.activeIdx === stBtn.index

                                                Layout.preferredWidth: styleTrack.cellWidth
                                                Layout.minimumWidth: 0
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: !isSel && stHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: stHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: String(stBtn.modelData)
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: stBtn.isSel
                                                    color: stBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.updateRuleField(ruleRowCard.ruleItem.target, "style", String(stBtn.modelData))
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
}
