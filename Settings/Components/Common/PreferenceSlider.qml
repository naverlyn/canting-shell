import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: ps
    property string title: ""
    property string subtitle: ""
    property string unit: ""
    property real minVal: 0
    property real maxVal: 100
    property real currentVal: 0
    property int decimalPlaces: 0
    signal valueChanged(real newVal)

    Layout.fillWidth: true
    height: 52

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 20

        // Left Label Column (Fixed width: guarantees 100% vertical alignment of seekbars)
        Item {
            Layout.preferredWidth: 280
            Layout.minimumWidth: 280
            Layout.maximumWidth: 280
            Layout.fillHeight: true

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 2

                Text {
                    width: parent.width
                    text: ps.title
                    font.family: Style.font
                    font.pixelSize: 13
                    font.bold: true
                    color: Style.theme.textPrimary
                    elide: Text.ElideRight
                }

                Text {
                    visible: ps.subtitle !== ""
                    width: parent.width
                    text: ps.subtitle
                    font.family: Style.font
                    font.pixelSize: 11
                    color: Style.theme.textSecondary
                    elide: Text.ElideRight
                }
            }
        }

        // Seekbar Track Area: Fills all remaining width across the card
        Rectangle {
            id: track
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Style.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)
            border.color: Style.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            Layout.alignment: Qt.AlignVCenter

            // Active progress fill bar
            Rectangle {
                id: fillBar
                height: parent.height
                radius: parent.radius
                width: Math.max(0, Math.min(parent.width, parent.width * ((ps.currentVal - ps.minVal) / Math.max(0.0001, ps.maxVal - ps.minVal))))
                color: Style.theme.accentPrimary ?? "#7aa2f7"

                Behavior on width {
                    enabled: !sliderMouse.pressed
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }

            // Outer halo ring on hover/press
            Rectangle {
                anchors.centerIn: knob
                width: knob.width + (sliderMouse.pressed ? 8 : (sliderMouse.containsMouse ? 6 : 0))
                height: width
                radius: width / 2
                color: {
                    const acc = Qt.color((Style.theme && Style.theme.accentPrimary) ? Style.theme.accentPrimary : "#7aa2f7");
                    return Qt.rgba(acc.r, acc.g, acc.b, sliderMouse.pressed ? 0.35 : (sliderMouse.containsMouse ? 0.2 : 0));
                }
                z: 1

                Behavior on width { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Tactile white knob
            Rectangle {
                id: knob
                width: sliderMouse.containsMouse || sliderMouse.pressed ? 17 : 15
                height: width
                radius: width / 2
                color: "#ffffff"
                border.color: (Style.theme && Style.theme.accentPrimary) ? Style.theme.accentPrimary : "#7aa2f7"
                border.width: 3
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(track.width - width, (track.width * ((ps.currentVal - ps.minVal) / Math.max(0.0001, ps.maxVal - ps.minVal))) - width / 2))
                z: 2

                Behavior on width { NumberAnimation { duration: 120 } }
                Behavior on x {
                    enabled: !sliderMouse.pressed
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: sliderMouse
                anchors.fill: parent
                anchors.margins: -8
                preventStealing: true
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                z: 3

                function updateValue(mouseX) {
                    let ratio = Math.max(0, Math.min(1, mouseX / width));
                    let raw = ps.minVal + ratio * (ps.maxVal - ps.minVal);
                    let val = ps.decimalPlaces > 0 ? parseFloat(raw.toFixed(ps.decimalPlaces)) : Math.round(raw);
                    ps.currentVal = val;
                    ps.valueChanged(val);
                }

                onPressed: (m) => { m.accepted = true; updateValue(m.x); }
                onPositionChanged: (m) => { if (pressed) { m.accepted = true; updateValue(m.x); } }
            }
        }

        // Value Label (Fixed width, right-aligned clean text without background)
        Text {
            Layout.preferredWidth: 50
            Layout.minimumWidth: 50
            Layout.maximumWidth: 50
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: (ps.decimalPlaces > 0 ? ps.currentVal.toFixed(ps.decimalPlaces) : String(Math.round(ps.currentVal))) + (ps.unit !== "" ? (" " + ps.unit) : "")
            font.family: Style.font
            font.pixelSize: 12
            font.bold: true
            color: Style.theme.accentPrimary ?? "#7aa2f7"
        }
    }
}
