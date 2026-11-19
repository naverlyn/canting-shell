import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../bar"
import ".."
import "./Wifi"

Item {
    id: root
    property var theme: DefaultTheme {}
    property string font

    readonly property var networks: WifiService.networkList
    readonly property bool wifiEnabled: WifiService.wifiEnabled
    readonly property string currentSsid: WifiService.currentSsid
    property string expandedSsid: ""
    property bool manageSavedExpanded: false
    property bool confirmForgetAll: false

    Timer {
        id: forgetAllResetTimer
        interval: 4000
        repeat: false
        onTriggered: root.confirmForgetAll = false
    }

    readonly property var connectedNetwork: {
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].ssid === currentSsid) return networks[i];
        }
        return null;
    }

    readonly property var savedNetworks: {
        const list = [];
        for (let i = 0; i < networks.length; i++) {
            const n = networks[i];
            if (n.ssid !== currentSsid && Boolean(WifiService.savedConnections[n.ssid])) {
                list.push(n);
            }
        }
        return list;
    }

    readonly property var availableNetworks: {
        const list = [];
        for (let i = 0; i < networks.length; i++) {
            const n = networks[i];
            if (n.ssid !== currentSsid && !Boolean(WifiService.savedConnections[n.ssid])) {
                list.push(n);
            }
        }
        return list;
    }

    onVisibleChanged: {
        if (visible) {
            WifiService.clearError();
            WifiService.refreshStatus();
            if (WifiService.wifiEnabled) WifiService.scan(false);
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: {
            WifiService.refreshStatus();
            if (WifiService.wifiEnabled) WifiService.scan(false);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        WifiHeaderBar {
            theme: root.theme
            font: root.font
            wifiEnabled: root.wifiEnabled
            onEnableRequested: WifiService.setWifiEnabled(true)
            onDisableRequested: {
                WifiService.setWifiEnabled(false);
                root.expandedSsid = "";
            }
        }

        // Inline error banner
        Rectangle {
            visible: WifiService.lastError !== ""
            Layout.fillWidth: true
            implicitHeight: settingsErrText.implicitHeight + 16
            radius: 10
            color: Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.14)
            border.color: Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.35)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                Text {
                    id: settingsErrText
                    Layout.fillWidth: true
                    text: WifiService.lastError
                    color: root.theme.accentRed
                    font.pixelSize: 12
                    font.family: root.font
                    wrapMode: Text.WordWrap
                }
                Text {
                    text: "✕"
                    color: root.theme.accentRed
                    font.pixelSize: 12
                    font.family: root.font
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiService.clearError()
                    }
                }
            }
        }

        // Disabled state card
        Rectangle {
            visible: !root.wifiEnabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰖪"
                    font.family: root.font
                    font.pixelSize: 32
                    color: root.theme.textMuted
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Wi-Fi is turned off"
                    font.family: root.font
                    font.pixelSize: 14
                    font.bold: true
                    color: root.theme.textPrimary
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Turn on Wi-Fi above to view and connect to available networks"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textSecondary
                }
            }
        }

        // Segmented Scrollable Content (Connected / Saved / Available)
        Flickable {
            visible: root.wifiEnabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: contentCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4
                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 1.5
                    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.2)
                }
            }

            ColumnLayout {
                id: contentCol
                width: parent.width - 8
                spacing: 14

                // 1. Connected Network Card
                Rectangle {
                    visible: root.connectedNetwork !== null
                    Layout.fillWidth: true
                    implicitHeight: connectedRow.implicitHeight + 12
                    radius: 12
                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.10)
                    border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.35)
                    border.width: 1

                    WifiNetworkRow {
                        id: connectedRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        theme: root.theme
                        font: root.font
                        networkData: root.connectedNetwork || ({ ssid: "", signal: 0, secured: false, band: "" })
                        isCurrent: true
                        isSaved: true
                        connectionDetails: WifiService.connectionDetails
                        isExpanded: root.connectedNetwork !== null && root.expandedSsid === root.connectedNetwork.ssid
                        connecting: false
                        disconnecting: WifiService.isDisconnecting

                        onToggleExpandRequested: ssid => {
                            root.expandedSsid = (root.expandedSsid === ssid) ? "" : ssid;
                        }
                        onDisconnectRequested: ssid => {
                            WifiService.disconnect(ssid);
                            root.expandedSsid = "";
                        }
                        onForgetRequested: ssid => {
                            WifiService.forget(ssid);
                            root.expandedSsid = "";
                        }
                        onCollapseRequested: root.expandedSsid = ""
                    }
                }

                // 2. Saved Networks Section
                ColumnLayout {
                    visible: root.savedNetworks.length > 0
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Saved networks"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textSecondary
                        Layout.leftMargin: 4
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: savedCol.implicitHeight + 12
                        radius: 12
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1

                        ColumnLayout {
                            id: savedCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 6
                            spacing: 2

                            Repeater {
                                model: root.savedNetworks

                                delegate: ColumnLayout {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 2

                                    WifiNetworkRow {
                                        Layout.fillWidth: true
                                        theme: root.theme
                                        font: root.font
                                        networkData: modelData
                                        isCurrent: false
                                        isSaved: true
                                        connectionDetails: ({})
                                        isExpanded: root.expandedSsid === modelData.ssid
                                        connecting: WifiService.isConnecting && WifiService.connectingSsid === modelData.ssid
                                        disconnecting: false

                                        onToggleExpandRequested: ssid => {
                                            root.expandedSsid = (root.expandedSsid === ssid) ? "" : ssid;
                                        }
                                        onConnectRequested: (ssid, password, hasSecurity) => {
                                            WifiService.connect(ssid, hasSecurity, password);
                                            root.expandedSsid = "";
                                        }
                                        onForgetRequested: ssid => {
                                            WifiService.forget(ssid);
                                            root.expandedSsid = "";
                                        }
                                        onCollapseRequested: root.expandedSsid = ""
                                    }

                                    Rectangle {
                                        visible: index < root.savedNetworks.length - 1
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 44
                                        Layout.rightMargin: 12
                                        height: 1
                                        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                                    }
                                }
                            }
                        }
                    }
                }

                // 3. Available Networks Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4

                        Text {
                            text: "Available networks"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textSecondary
                            Layout.fillWidth: true
                        }

                        Text {
                            text: WifiService.isScanning ? "Scanning..." : "Refresh"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: WifiService.isScanning ? root.theme.textMuted : root.theme.accentPrimary

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: WifiService.isScanning ? Qt.ArrowCursor : Qt.PointingHandCursor
                                enabled: !WifiService.isScanning
                                onClicked: WifiService.scan(true)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: root.availableNetworks.length > 0 ? (availCol.implicitHeight + 12) : 96
                        radius: 12
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1

                        ColumnLayout {
                            id: availCol
                            visible: root.availableNetworks.length > 0
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 6
                            spacing: 2

                            Repeater {
                                model: root.availableNetworks

                                delegate: ColumnLayout {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 2

                                    WifiNetworkRow {
                                        Layout.fillWidth: true
                                        theme: root.theme
                                        font: root.font
                                        networkData: modelData
                                        isCurrent: false
                                        isSaved: false
                                        connectionDetails: ({})
                                        isExpanded: root.expandedSsid === modelData.ssid
                                        connecting: WifiService.isConnecting && WifiService.connectingSsid === modelData.ssid
                                        disconnecting: false

                                        onToggleExpandRequested: ssid => {
                                            root.expandedSsid = (root.expandedSsid === ssid) ? "" : ssid;
                                        }
                                        onConnectRequested: (ssid, password, hasSecurity) => {
                                            WifiService.connect(ssid, hasSecurity, password);
                                            root.expandedSsid = "";
                                        }
                                        onCollapseRequested: root.expandedSsid = ""
                                    }

                                    Rectangle {
                                        visible: index < root.availableNetworks.length - 1
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 44
                                        Layout.rightMargin: 12
                                        height: 1
                                        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                                    }
                                }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            visible: root.availableNetworks.length === 0

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: WifiService.isScanning ? "Scanning for networks..." : "No other networks nearby"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textSecondary
                            }
                        }
                    }
                }

                // 4. Additional settings (Manage saved networks)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    spacing: 8

                    Text {
                        text: "Additional settings"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textSecondary
                        Layout.leftMargin: 4
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: additionalCol.implicitHeight + 12
                        radius: 12
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            id: additionalCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 6
                            spacing: 4

                            // Header row: Manage saved networks
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 50
                                Layout.preferredHeight: 50
                                radius: 10
                                color: manageRowHov.hovered
                                    ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
                                    : "transparent"

                                HoverHandler { id: manageRowHov }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.manageSavedExpanded = !root.manageSavedExpanded
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: "Manage saved networks"
                                            color: root.theme.textPrimary
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: WifiService.savedConnectionList.length === 0
                                                ? "No saved Wi-Fi profiles"
                                                : (WifiService.savedConnectionList.length + (WifiService.savedConnectionList.length === 1 ? " saved network" : " saved networks"))
                                            color: root.theme.textSecondary
                                            font.family: root.font
                                            font.pixelSize: 11
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Forget all button (2-step confirm)
                                    Rectangle {
                                        visible: WifiService.savedConnectionList.length > 0
                                        Layout.preferredWidth: forgetAllText.implicitWidth + 18
                                        Layout.preferredHeight: 28
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 7
                                        color: root.confirmForgetAll
                                            ? root.theme.accentRed
                                            : (forgetAllHov.hovered
                                                ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.16)
                                                : Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.08))
                                        border.color: root.theme.accentRed
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                        HoverHandler { id: forgetAllHov }

                                        Text {
                                            id: forgetAllText
                                            anchors.centerIn: parent
                                            text: root.confirmForgetAll ? "Confirm forget all?" : "Forget all"
                                            color: root.confirmForgetAll ? root.theme.bgBase : root.theme.accentRed
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (!root.confirmForgetAll) {
                                                    root.confirmForgetAll = true;
                                                    forgetAllResetTimer.restart();
                                                } else {
                                                    root.confirmForgetAll = false;
                                                    forgetAllResetTimer.stop();
                                                    WifiService.forgetAll();
                                                    root.expandedSsid = "";
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: "›"
                                        color: root.theme.textMuted
                                        font.family: root.font
                                        font.pixelSize: 16
                                        font.bold: true
                                        Layout.preferredWidth: 16
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.alignment: Qt.AlignVCenter
                                        rotation: root.manageSavedExpanded ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }

                            // Expanded list of all saved networks (animated container)
                            Item {
                                id: savedManageClip
                                Layout.fillWidth: true
                                clip: true
                                readonly property real targetHeight: Math.min(savedManageListCol.implicitHeight, 280)
                                implicitHeight: root.manageSavedExpanded ? targetHeight : 0
                                opacity: root.manageSavedExpanded ? 1 : 0
                                enabled: root.manageSavedExpanded

                                Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                Flickable {
                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: savedManageListCol.implicitHeight
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    ScrollBar.vertical: ScrollBar {
                                        policy: ScrollBar.AsNeeded
                                        width: 4
                                        contentItem: Rectangle {
                                            implicitWidth: 3
                                            radius: 1.5
                                            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.2)
                                        }
                                    }

                                    ColumnLayout {
                                        id: savedManageListCol
                                        width: parent.width - 6
                                        spacing: 2

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                    Layout.rightMargin: 12
                                    height: 1
                                    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                                }

                                Text {
                                    visible: WifiService.savedConnectionList.length === 0
                                    Layout.fillWidth: true
                                    Layout.topMargin: 10
                                    Layout.bottomMargin: 10
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "No saved Wi-Fi networks"
                                    color: root.theme.textMuted
                                    font.family: root.font
                                    font.pixelSize: 12
                                }

                                Repeater {
                                    model: WifiService.savedConnectionList

                                    delegate: ColumnLayout {
                                        required property string modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 14
                                            Layout.rightMargin: 12
                                            Layout.topMargin: 6
                                            Layout.bottomMargin: 6
                                            spacing: 10

                                            Text {
                                                text: "󰖩"
                                                color: modelData === root.currentSsid ? root.theme.accentPrimary : root.theme.textSecondary
                                                font.family: root.font
                                                font.pixelSize: 15
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Text {
                                                    text: modelData
                                                    color: root.theme.textPrimary
                                                    font.family: root.font
                                                    font.pixelSize: 12
                                                    font.bold: modelData === root.currentSsid
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    visible: modelData === root.currentSsid
                                                    text: "Connected"
                                                    color: root.theme.accentPrimary
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 66
                                                Layout.preferredHeight: 26
                                                Layout.alignment: Qt.AlignVCenter
                                                radius: 6
                                                color: savedForgetHov.hovered
                                                    ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.14)
                                                    : "transparent"
                                                border.color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
                                                border.width: 1
                                                HoverHandler { id: savedForgetHov }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Forget"
                                                    color: savedForgetHov.hovered ? root.theme.accentRed : root.theme.textSecondary
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: WifiService.forget(modelData)
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: index < WifiService.savedConnectionList.length - 1
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 38
                                            Layout.rightMargin: 12
                                            height: 1
                                            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
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
