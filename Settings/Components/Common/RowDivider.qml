import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    property int sideMargin: 12
    property real alpha: 0.5
    Layout.fillWidth: true
    Layout.leftMargin: sideMargin
    Layout.rightMargin: sideMargin
    height: 1
    color: Style.withAlpha(Style.theme.bgBorder, alpha)
}
