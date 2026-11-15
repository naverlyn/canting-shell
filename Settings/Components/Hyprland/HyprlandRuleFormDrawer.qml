import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

Rectangle {
    id: ruleFormDrawer
    required property var root
    readonly property bool isDrawerOpen: root.isAddingRule || root.editingRuleName !== ""
    Layout.fillWidth: true
    visible: implicitHeight > 0 || opacity > 0
    implicitHeight: isDrawerOpen ? (ruleFormCol.implicitHeight + 24) : 0
    opacity: isDrawerOpen ? 1.0 : 0.0
    radius: 10
    color: root.theme.bgBase
    border.color: root.theme.accentPrimary
    border.width: 1
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    ColumnLayout {
        id: ruleFormCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.editingRuleName !== "" ? ("Edit Lua Rule: " + root.editingRuleName) : "Create New Lua Window / Layer Rule"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.accentPrimary
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Configs/WindowWorkspaces.lua"
                font.family: root.font
                font.pixelSize: 10
                color: root.theme.textMuted
            }
        }

        /* Row 1: Rule Type & Rule Name */
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Type:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 70
            }

            /* Segmented Rule Type Track with Sliding Selection Pill */
            Rectangle {
                id: ruleTypeSegmentTrack
                implicitWidth: 240
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                readonly property int activeIdx: root.formRuleType === "layer_rule" ? 1 : 0
                readonly property real cellWidth: (width - 6 - 3) / 2

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: ruleTypeSegmentTrack.cellWidth
                    x: 3 + ruleTypeSegmentTrack.activeIdx * (ruleTypeSegmentTrack.cellWidth + 3)
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
                        model: [
                            { id: "window_rule", label: "hl.window_rule" },
                            { id: "layer_rule",  label: "hl.layer_rule" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool isSel: ruleTypeSegmentTrack.activeIdx === index
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && rtHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: rtHover }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: isSel
                                color: isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: isSel || rtHover.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.formRuleType = modelData.id
                            }
                        }
                    }
                }
            }

            Text {
                text: "Name:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formNameInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formNameInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formNameInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formRuleName
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formRuleName) root.formRuleName = text

                    Text {
                        text: "Unique rule identifier (e.g. my-custom-float)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formNameInput.text && !formNameInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        /* Row 2: Match Class / Namespace */
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Match:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 70
            }

            Rectangle {
                visible: root.formRuleType === "window_rule"
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formClassInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formClassInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formClassInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formMatchClass
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formMatchClass) root.formMatchClass = text

                    Text {
                        text: "class regex (e.g. ^([Ff]irefox|org.mozilla.firefox)$)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formClassInput.text && !formClassInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                visible: root.formRuleType === "layer_rule"
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formNsInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formNsInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formNsInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formMatchNamespace
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formMatchNamespace) root.formMatchNamespace = text

                    Text {
                        text: "layer namespace (e.g. rofi, notifications, quickshell:overview)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formNsInput.text && !formNsInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        /* Row 2b: Title & Tag Match Criteria (for Window Rules) */
        RowLayout {
            visible: root.formRuleType === "window_rule"
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Filter:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 70
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formTitleInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formTitleInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formTitleInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formMatchTitle
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formMatchTitle) root.formMatchTitle = text

                    Text {
                        text: "title regex (optional, e.g. ^(Picture-in-Picture|Save File)$)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formTitleInput.text && !formTitleInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 200
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formTagMatchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formTagMatchInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formTagMatchInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formMatchTag
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formMatchTag) root.formMatchTag = text

                    Text {
                        text: "match tag (e.g. browser*)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formTagMatchInput.text && !formTagMatchInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        /* Row 3: Window Rule Effects (Boolean pills + Parameters) */
        RowLayout {
            visible: root.formRuleType === "window_rule"
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Flags:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 70
            }

            /* Unified Track for Boolean Flags */
            Rectangle {
                implicitWidth: flagRow.implicitWidth + 6
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    id: flagRow
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: [
                            { key: "float",    label: "Float" },
                            { key: "center",   label: "Center" },
                            { key: "pin",      label: "Pin" },
                            { key: "no_blur",  label: "No Blur" },
                            { key: "no_anim",  label: "No Anim" },
                            { key: "no_focus", label: "No Focus" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isOn: {
                                if (modelData.key === "float") return root.formEffectFloat;
                                if (modelData.key === "center") return root.formEffectCenter;
                                if (modelData.key === "pin") return root.formEffectPin;
                                if (modelData.key === "no_blur") return root.formEffectNoBlur;
                                if (modelData.key === "no_anim") return root.formEffectNoAnim;
                                if (modelData.key === "no_focus") return root.formEffectNoFocus;
                                return false;
                            }
                            implicitWidth: flagTxt.implicitWidth + 18
                            Layout.fillHeight: true
                            radius: 5
                            color: isOn ? root.theme.bgSelected : (flagHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                            border.color: isOn ? root.theme.accentPrimary : "transparent"
                            border.width: 1
                            scale: flagMouse.pressed ? 0.96 : 1.0

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                            HoverHandler { id: flagHover }

                            Text {
                                id: flagTxt
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: isOn
                                color: isOn ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: isOn || flagHover.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: flagMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.key === "float") root.formEffectFloat = !root.formEffectFloat;
                                    else if (modelData.key === "center") root.formEffectCenter = !root.formEffectCenter;
                                    else if (modelData.key === "pin") root.formEffectPin = !root.formEffectPin;
                                    else if (modelData.key === "no_blur") root.formEffectNoBlur = !root.formEffectNoBlur;
                                    else if (modelData.key === "no_anim") root.formEffectNoAnim = !root.formEffectNoAnim;
                                    else if (modelData.key === "no_focus") root.formEffectNoFocus = !root.formEffectNoFocus;
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        /* Row 4: Window Rule Value Effects (Opacity, Size, Move, Workspace, Tag) */
        RowLayout {
            visible: root.formRuleType === "window_rule"
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Values:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 70
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formOpInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formOpInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formOpInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formEffectOpacity
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formEffectOpacity) root.formEffectOpacity = text

                    Text {
                        text: "opacity (e.g. 0.9 0.8)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formOpInput.text && !formOpInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formSizeInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formSizeInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formSizeInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formEffectSize
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formEffectSize) root.formEffectSize = text

                    Text {
                        text: "size (e.g. (monitor_w*0.7) (monitor_h*0.7))"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formSizeInput.text && !formSizeInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 120
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formWsInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formWsInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formWsInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formEffectWorkspace
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formEffectWorkspace) root.formEffectWorkspace = text

                    Text {
                        text: "workspace (e.g. 2)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formWsInput.text && !formWsInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 135
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formAssignTagInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formAssignTagInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formAssignTagInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formEffectTag
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formEffectTag) root.formEffectTag = text

                    Text {
                        text: "assign tag (+browser)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formAssignTagInput.text && !formAssignTagInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        /* Row 4b: Layer Rule Effects */
        RowLayout {
            visible: root.formRuleType === "layer_rule"
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Layer:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 70
            }

            Rectangle {
                implicitWidth: 116
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 5
                    color: root.formLayerBlur ? root.theme.bgSelected : (layerBlurHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                    border.color: root.formLayerBlur ? root.theme.accentPrimary : "transparent"
                    border.width: 1
                    scale: layerBlurMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    HoverHandler { id: layerBlurHover }

                    Text {
                        anchors.centerIn: parent
                        text: "Blur Layer"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: root.formLayerBlur
                        color: root.formLayerBlur ? root.theme.accentPrimary : root.theme.textPrimary
                        opacity: root.formLayerBlur || layerBlurHover.hovered ? 1.0 : 0.75
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: layerBlurMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.formLayerBlur = !root.formLayerBlur
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 180
                height: 32
                radius: 7
                color: root.theme.bgSurface
                border.color: formIgnoreAlphaInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: formIgnoreAlphaInput.activeFocus ? 2 : 1
                clip: true

                TextInput {
                    id: formIgnoreAlphaInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.formLayerIgnoreAlpha
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    selectByMouse: true
                    onTextChanged: if (text !== root.formLayerIgnoreAlpha) root.formLayerIgnoreAlpha = text

                    Text {
                        text: "ignore_alpha (e.g. 0.5)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        visible: !formIgnoreAlphaInput.text && !formIgnoreAlphaInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        /* Row 5: Cancel / Delete / Save Buttons */
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                visible: root.editingRuleName !== ""
                implicitWidth: delRuleTxt.implicitWidth + 24
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 5
                    color: delRuleHover.hovered ? Qt.rgba(0.95, 0.25, 0.35, 0.2) : "transparent"
                    border.color: delRuleHover.hovered ? "#f7768e" : "transparent"
                    border.width: 1
                    scale: delRuleMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    HoverHandler { id: delRuleHover }

                    Text {
                        id: delRuleTxt
                        anchors.centerIn: parent
                        text: "Delete Rule"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: delRuleHover.hovered ? "#f7768e" : root.theme.textSecondary
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: delRuleMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.deleteWindowRule(root.editingRuleName)
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: cancelRuleTxt.implicitWidth + 28
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 5
                    color: cancelRuleHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                    scale: cancelRuleMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    HoverHandler { id: cancelRuleHover }

                    Text {
                        id: cancelRuleTxt
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: cancelRuleHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: cancelRuleMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isAddingRule = false;
                            root.editingRuleName = "";
                        }
                    }
                }
            }

            Rectangle {
                readonly property bool canSave: root.formRuleName.trim().length > 0
                implicitWidth: saveRuleTxt.implicitWidth + 32
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                opacity: canSave ? 1.0 : 0.45

                Behavior on opacity { NumberAnimation { duration: 150 } }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 5
                    color: parent.canSave ? root.theme.bgSelected : "transparent"
                    border.color: parent.canSave ? root.theme.accentPrimary : "transparent"
                    border.width: 1
                    scale: saveRuleMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

                    Text {
                        id: saveRuleTxt
                        anchors.centerIn: parent
                        text: root.editingRuleName !== "" ? "Save Rule Changes" : "Add Lua Rule"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: parent.parent.canSave ? root.theme.accentPrimary : root.theme.textMuted
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: saveRuleMouse
                        anchors.fill: parent
                        enabled: parent.parent.canSave
                        cursorShape: parent.parent.canSave ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.saveRuleForm()
                    }
                }
            }
        }
    }
}
