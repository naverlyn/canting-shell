import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../notifications"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: inspectorSection
    title: "Element Styling"
    subtitle: "Fine-tune the size, typography, and appearance of the selected notification element"

    readonly property var inspectorTabs: [
        { id: "icon",        label: "App Icon",       icon: "󰂚" },
        { id: "appName",     label: "Header & Time",  icon: "󰀻" },
        { id: "title",       label: "Title",          icon: "󰗴" },
        { id: "body",        label: "Body Message",   icon: "󰦨" },
        { id: "image",       label: "Preview Image",  icon: "󰋩" },
        { id: "buttons",     label: "Action Buttons", icon: "󰘊" },
        { id: "progressBar", label: "Timeout Bar",    icon: "󰔟" },
        { id: "card",        label: "Card & Accent",  icon: "󰒓" }
    ]

    readonly property string activeTabId: {
        const cur = root.selectedInspectorBlock;
        if (cur === "timestamp" || cur === "closeBtn") return "appName";
        return cur || "icon";
    }

    property real tabRevealProgress: 1.0
    onActiveTabIdChanged: {
        tabRevealProgress = 0.0;
        tabRevealAnim.restart();
    }

    NumberAnimation {
        id: tabRevealAnim
        target: inspectorSection
        property: "tabRevealProgress"
        from: 0.0
        to: 1.0
        duration: 160
        easing.type: Easing.OutCubic
    }

    // Top Selector Pill Strip
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 42
        radius: 9
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4

            Repeater {
                model: inspectorSection.inspectorTabs
                delegate: Rectangle {
                    id: tabPill
                    required property var modelData
                    readonly property bool isSel: inspectorSection.activeTabId === modelData.id

                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: isSel
                        ? root.theme.bgSelected
                        : (pillHover.hovered ? root.theme.bgHover : "transparent")
                    border.color: isSel ? root.theme.accentPrimary : "transparent"
                    border.width: isSel ? 1 : 0
                    scale: pillMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on scale { NumberAnimation { duration: 90 } }

                    HoverHandler { id: pillHover }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: tabPill.modelData.icon
                            font.family: root.font
                            font.pixelSize: 12
                            color: tabPill.isSel ? root.theme.accentPrimary : root.theme.textSecondary
                        }

                        Text {
                            text: tabPill.modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: tabPill.isSel
                            color: tabPill.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: pillMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = tabPill.modelData.id
                    }
                }
            }
        }
    }

    // Inspector Content Container
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inspectorContentCol.implicitHeight + 16
        radius: 10
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        clip: true
        Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: inspectorContentCol
            opacity: inspectorSection.tabRevealProgress
            transform: Translate { y: (1.0 - inspectorSection.tabRevealProgress) * 6 }
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            NotificationInspectorIconHeaderGroup {
                visible: inspectorSection.activeTabId === "icon" || inspectorSection.activeTabId === "appName"
                root: inspectorSection.root
                activeTabId: inspectorSection.activeTabId
            }

            NotificationInspectorTextMediaGroup {
                visible: inspectorSection.activeTabId === "title" || inspectorSection.activeTabId === "body" || inspectorSection.activeTabId === "image"
                root: inspectorSection.root
                activeTabId: inspectorSection.activeTabId
            }

            NotificationInspectorActionsChromeGroup {
                visible: inspectorSection.activeTabId === "buttons" || inspectorSection.activeTabId === "progressBar" || inspectorSection.activeTabId === "card"
                root: inspectorSection.root
                activeTabId: inspectorSection.activeTabId
            }
        }
    }
}
