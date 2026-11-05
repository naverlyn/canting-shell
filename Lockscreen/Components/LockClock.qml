import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: clockRoot

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockRoot.currentTime = new Date()
    }

    readonly property string timePattern: LockscreenConfig.timeFormat === "12h" ? "hh:mm AP" : "hh:mm"
    readonly property string timeString: Qt.formatDateTime(clockRoot.currentTime, clockRoot.timePattern)
    readonly property string secondsString: Qt.formatDateTime(clockRoot.currentTime, "ss")
    readonly property string dateString: Qt.formatDateTime(clockRoot.currentTime, "dddd, dd MMMM yyyy")

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        spacing: 4

        RowLayout {
            spacing: 8

            Text {
                text: clockRoot.timeString
                font.family: clockRoot.font
                font.pixelSize: 84
                font.bold: true
                color: clockRoot.theme.textPrimary

                style: Text.Outline
                styleColor: clockRoot.theme.bgOverlay
            }

            Text {
                visible: LockscreenConfig.showSeconds
                text: clockRoot.secondsString
                font.family: clockRoot.font
                font.pixelSize: 28
                font.bold: true
                color: clockRoot.theme.accentPrimary
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 18

                style: Text.Outline
                styleColor: clockRoot.theme.bgOverlay
            }
        }

        Text {
            visible: LockscreenConfig.showDate
            text: clockRoot.dateString
            font.family: clockRoot.font
            font.pixelSize: 22
            font.weight: Font.DemiBold
            color: clockRoot.theme.textSecondary
            Layout.leftMargin: 4

            style: Text.Outline
            styleColor: clockRoot.theme.bgOverlay
        }
    }
}
