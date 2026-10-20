import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../bar"
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    property string conditionText: "Clear"
    property string tempText: "--°C"
    property string feelsLikeText: "--°C"
    property string humidityText: "--%"
    property string windText: "-- km/h"
    property bool isRefreshing: false

    readonly property string locationName: (typeof BarConfig !== "undefined" && BarConfig.weatherLocation)
        ? BarConfig.weatherLocation
        : "Bekasi"

    width: parent ? parent.width : 300
    height: weatherCol.implicitHeight + 24
    implicitHeight: weatherCol.implicitHeight + 24
    implicitWidth: 300
    radius: 10
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
    border.color: root.theme.bgBorder
    border.width: 1

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    function parseFromSummary(raw) {
        if (!raw || raw === "Loading..." || raw.includes("N/A")) return;
        const tempMatch = raw.match(/([+-]?\d+°[CF])/);
        if (tempMatch && root.tempText === "--°C") {
            root.tempText = tempMatch[1];
        }
        const windMatch = raw.match(/([↑↓←→↖↗↘↙]?\d+\s*km\/h|[↑↓←→↖↗↘↙]?\d+\s*mph)/i);
        if (windMatch && root.windText === "-- km/h") {
            root.windText = windMatch[1];
        }
    }

    function getWeatherIcon(cond) {
        const c = (cond || "").toLowerCase();
        if (c.includes("thunder") || c.includes("storm")) return "󰙾";
        if (c.includes("rain") || c.includes("drizzle") || c.includes("shower")) return "󰖗";
        if (c.includes("snow") || c.includes("sleet") || c.includes("blizzard")) return "󰖘";
        if (c.includes("fog") || c.includes("mist") || c.includes("haze")) return "󰖑";
        if (c.includes("overcast") || c.includes("cloudy")) return "󰖐";
        if (c.includes("partly")) return "󰖕";
        if (c.includes("clear") || c.includes("sunny")) return "󰖙";
        return "󰖕";
    }

    function refresh() {
        root.parseFromSummary(SystemInfo.weatherInfo);
        if (detailProc.running) return;
        root.isRefreshing = true;
        const loc = root.locationName;
        const u = (typeof BarConfig !== "undefined" && BarConfig.weatherUnit === "u") ? "u" : "m";
        detailProc.command = [
            "sh", "-c",
            "curl -s --connect-timeout 5 \"https://wttr.in/" + loc + "?format=%C|%t|%f|%h|%w&" + u + "\" 2>/dev/null | head -n 1"
        ];
        detailProc.running = true;
    }

    Process {
        id: detailProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.isRefreshing = false;
                const line = text.trim();
                if (!line || line.includes("<") || line.includes("Unknown")) return;
                const parts = line.split("|");
                if (parts.length >= 5) {
                    if (parts[0].trim()) root.conditionText = parts[0].trim();
                    if (parts[1].trim()) root.tempText = parts[1].trim().replace(/^\+/, "");
                    if (parts[2].trim()) root.feelsLikeText = parts[2].trim().replace(/^\+/, "");
                    if (parts[3].trim()) root.humidityText = parts[3].trim();
                    if (parts[4].trim()) root.windText = parts[4].trim();
                }
            }
        }
        onExited: root.isRefreshing = false
    }

    Component.onCompleted: {
        root.parseFromSummary(SystemInfo.weatherInfo);
        root.refresh();
    }

    Connections {
        target: SystemInfo
        function onWeatherInfoChanged() {
            root.parseFromSummary(SystemInfo.weatherInfo);
        }
    }

    ColumnLayout {
        id: weatherCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
        }
        spacing: 10

        // Header Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "󰖐"
                font.family: root.font
                font.pixelSize: 13
                color: root.theme.accentCyan
            }

            Text {
                text: "Weather · " + root.locationName
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                width: 22
                height: 22
                radius: 6
                color: refreshMouse.containsMouse
                    ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)
                    : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.isRefreshing ? root.theme.accentPrimary : root.theme.textMuted
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SystemInfo.refreshWeather();
                        root.refresh();
                    }
                }
            }
        }

        // Main Condition Banner
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 54
            radius: 8
            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
            border.color: Qt.rgba(root.theme.bgBorder.r, root.theme.bgBorder.g, root.theme.bgBorder.b, 0.5)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Rectangle {
                    width: 36
                    height: 36
                    radius: 10
                    color: Qt.rgba(root.theme.accentCyan.r, root.theme.accentCyan.g, root.theme.accentCyan.b, 0.16)

                    Text {
                        anchors.centerIn: parent
                        text: root.getWeatherIcon(root.conditionText)
                        font.family: root.font
                        font.pixelSize: 18
                        color: root.theme.accentCyan
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.conditionText
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: SystemInfo.weatherInfo || root.locationName
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: root.tempText
                    font.family: root.font
                    font.pixelSize: 18
                    font.bold: true
                    color: root.theme.accentPrimary
                }
            }
        }

        // 3 Mini Detail Pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { icon: "󰔏", label: "Feels", value: root.feelsLikeText },
                    { icon: "󰖎", label: "Humid", value: root.humidityText },
                    { icon: "󰖝", label: "Wind",  value: root.windText }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 80
                    implicitHeight: 38
                    radius: 7
                    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.icon + " " + modelData.label
                            font.family: root.font
                            font.pixelSize: 9
                            color: root.theme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.value
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }
                }
            }
        }
    }
}
