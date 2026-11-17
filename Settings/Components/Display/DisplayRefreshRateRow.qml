import QtQuick
import QtQuick.Layouts
import ".."

Item {
    required property var root
    Layout.fillWidth: true
    implicitHeight: 52
    opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
    enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

    RowLayout {
        id: rateRowLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Refresh Rate"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "Frame update frequency at " + root.currentResString.replace("x", "×")
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        AppDropdown {
            visible: root.availableRatesForCurrentRes.length > 0
            theme: root.theme
            font: root.font
            width: 220
            implicitWidth: 220
            menuWidth: 220
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            placeholder: "Select refresh rate..."
            options: (root.availableRatesForCurrentRes || []).map(r => ({
                desktop: r.mode,
                name: r.label,
                desc: ""
            }))
            currentValue: {
                if (!root.selectedMonitor) return "";
                const rates = root.availableRatesForCurrentRes || [];
                const curRate = parseFloat(root.currentRateString);
                for (let i = 0; i < rates.length; i++) {
                    if (root.selectedMonitor.selectedMode === rates[i].mode || Math.abs(curRate - rates[i].rateNum) < 0.35) {
                        return rates[i].mode;
                    }
                }
                return root.selectedMonitor.selectedMode || "";
            }
            onSelected: (val) => root.selectMode(val)
        }
    }
}
