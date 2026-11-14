import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."
import "../../utils/ColorUtils.js" as ColorUtils

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

    function resolveColor(colStr, fallbackColor) { return ColorUtils.resolveColorToken(root.theme, colStr, fallbackColor); }

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

