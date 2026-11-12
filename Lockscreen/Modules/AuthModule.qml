import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."

Item {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    property string username: Quickshell.env("USER") || "xeana"
    property bool isAuthenticating: false
    property string errorMessage: ""

    signal submitPassword(string password)

    function resolveColor(colStr, fallbackColor) {
        const t = root.theme;
        if (!colStr) return fallbackColor;
        const str = String(colStr).trim();
        if (str.startsWith("#")) return str;
        if (str === "$accent" || str === "$accentPrimary" || str === "$mauve" || str === "$pink" || str === "$color5" || str === "$color13") return t.accentPrimary;
        if (str === "$blue" || str === "$cyan" || str === "$sapphire" || str === "$sky" || str === "$lavender" || str === "$color4" || str === "$color6" || str === "$color12") return t.accentCyan;
        if (str === "$green" || str === "$teal" || str === "$color2" || str === "$color14") return t.accentGreen;
        if (str === "$yellow" || str === "$orange" || str === "$peach" || str === "$color3" || str === "$color11") return t.accentOrange;
        if (str === "$red" || str === "$maroon" || str === "$flamingo" || str === "$color1" || str === "$color9") return t.accentRed;
        if (str === "$text" || str === "$rosewater" || str === "$color15" || str === "$foreground") return t.textPrimary;
        if (str === "$secondary" || str === "$subtext1" || str === "$color10" || str === "$color7") return t.textSecondary;
        if (str === "$muted" || str === "$subtext0" || str === "$overlay2" || str === "$color8") return t.textMuted;
        if (str === "$surface2" || str === "$overlay1") return t.bgSelected;
        if (str === "$surface1" || str === "$overlay0") return t.bgHover;
        if (str === "$surface0" || str === "$color0") return t.bgSurface;
        if (str === "$base" || str === "$mantle" || str === "$crust" || str === "$background") return t.bgBase;
        return fallbackColor;
    }

    readonly property color resolvedOuter: resolveColor((root.moduleData && root.moduleData.color) ? root.moduleData.color : LockscreenConfig.input_outer_color, root.theme.accentPrimary)
    readonly property color resolvedInner: resolveColor(LockscreenConfig.input_inner_color, root.theme.bgSurface)
    readonly property color resolvedFont: resolveColor(LockscreenConfig.input_font_color, root.theme.textPrimary)

    readonly property real sFactor: root.scaleFactor
    readonly property real avatarSize: Math.max(40, Math.round(96 * sFactor))
    readonly property real inputW: Math.max(160, Math.round(280 * sFactor))
    readonly property real inputH: Math.max(26, Math.round(48 * sFactor))

    implicitWidth: Math.max(inputW, avatarSize) + Math.round(16 * sFactor)
    implicitHeight: mainCol.implicitHeight

    ColumnLayout {
        id: mainCol
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Math.max(4, Math.round(12 * root.sFactor))

        // Avatar Frame
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: root.avatarSize
            height: root.avatarSize

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: root.resolvedInner
                border.width: Math.max(1.5, Math.round(3 * root.sFactor))
                border.color: root.isAuthenticating
                              ? root.theme.accentCyan
                              : (root.errorMessage !== ""
                                 ? root.theme.accentRed
                                 : root.resolvedOuter)

                Behavior on border.color { ColorAnimation { duration: 180 } }

                Image {
                    id: faceImg
                    anchors.fill: parent
                    anchors.margins: Math.max(1, Math.round(2 * root.sFactor))
                    source: LockscreenConfig.faceIconPath !== "" ? ("file://" + LockscreenConfig.faceIconPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: faceImg.status !== Image.Ready
                    text: "󰀉"
                    font.family: root.font
                    font.pixelSize: Math.max(16, Math.round(42 * root.sFactor))
                    color: root.resolvedOuter
                }
            }
        }

        // Username
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.username
            font.family: root.font
            font.pixelSize: Math.max(9, Math.round(16 * root.sFactor))
            font.bold: true
            color: root.theme.textPrimary
            style: Text.Outline
            styleColor: root.theme.bgOverlay
        }

        // Password Input Box
        Rectangle {
            id: inputPill
            Layout.alignment: Qt.AlignHCenter
            width: root.inputW
            height: root.inputH
            radius: Math.round(14 * root.sFactor)
            color: Qt.rgba(root.resolvedInner.r, root.resolvedInner.g, root.resolvedInner.b, 0.82)
            border.color: root.isAuthenticating
                ? root.theme.accentCyan
                : (root.errorMessage !== ""
                   ? root.theme.accentRed
                   : root.resolvedOuter)
            border.width: Math.max(1.5, Math.round(2.5 * root.sFactor))

            Behavior on border.color { ColorAnimation { duration: 160 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(14 * root.sFactor)
                anchors.rightMargin: Math.round(14 * root.sFactor)
                spacing: Math.round(8 * root.sFactor)

                Text {
                    text: "󰌾"
                    font.family: root.font
                    font.pixelSize: Math.max(9, Math.round(14 * root.sFactor))
                    color: root.resolvedOuter
                }

                Text {
                    Layout.fillWidth: true
                    text: LockscreenConfig.input_placeholder || "Password"
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(12 * root.sFactor))
                    color: Qt.rgba(root.resolvedFont.r, root.resolvedFont.g, root.resolvedFont.b, 0.45)
                    elide: Text.ElideRight
                }
            }
        }
    }
}

