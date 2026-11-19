import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../bar"
import ".."

PanelWindow {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Lato Nerd Font"

    property bool wifiEnabled: WifiService.wifiEnabled
    readonly property string currentSsid: WifiService.currentSsid
    readonly property var networkList: WifiService.networkList
    property string selectedSsid: ""
    property bool selectedSsidSecured: false

    // Track state and selection
    property string expandedSsid: ""
    property int selectedIndex: 0

    signal setWifiRequested(bool enabled)
    signal toggleWifiRequested()
    signal networkConnected(string ssid)
    signal networkDisconnected(string ssid)

    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-wifi-selector"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    property bool closing: false

    function requestClose() {
        if (!root.visible || root.closing) return;
        root.closing = true;
        openAnim.stop();
        closeAnim.start();
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: wifiMainRect; property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
        NumberAnimation { target: wifiMainRect; property: "scale"; from: 0.96; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: wifiMainRect; property: "opacity"; to: 0.0; duration: 110; easing.type: Easing.InCubic }
        NumberAnimation { target: wifiMainRect; property: "scale"; to: 0.97; duration: 110; easing.type: Easing.InCubic }
        onFinished: {
            root.closing = false;
            root.visible = false;
        }
    }

    // Reset state and grab keyboard focus when opened
    onVisibleChanged: {
        if (visible) {
            root.closing = false;
            selectedIndex = 0;
            expandedSsid = "";
            WifiService.clearError();
            WifiService.refreshStatus();
            scanWifi();
            openAnim.start();
            Qt.callLater(() => networkListView.forceActiveFocus());
        } else {
            expandedSsid = "";
            WifiService.clearError();
        }
    }

    onWifiEnabledChanged: {
        if (wifiEnabled) {
            if (root.visible) scanDelayTimer.restart();
        } else {
            root.expandedSsid = "";
        }
    }

    Timer {
        id: scanDelayTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (root.visible && root.wifiEnabled) {
                WifiService.scan(false);
            }
        }
    }

    Timer {
        id: periodicScanTimer
        interval: 15000
        repeat: true
        running: root.visible && root.wifiEnabled
        onTriggered: WifiService.scan(false)
    }

    Connections {
        target: WifiService
        function onNetworkConnected(ssid) {
            root.networkConnected(ssid);
            if (root.visible) root.requestClose();
        }
        function onNetworkDisconnected(ssid) {
            root.networkDisconnected(ssid);
        }
    }

    function scanWifi() {
        if (root.wifiEnabled) {
            WifiService.scan(false);
        }
    }

    function connectToNetwork(password) {
        WifiService.connect(selectedSsid, selectedSsidSecured, password);
    }

    function disconnectFromNetwork(ssid) {
        root.selectedSsid = ssid || root.currentSsid;
        WifiService.disconnect(root.selectedSsid);
    }

    // Undimmed transparent backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: root.requestClose()
    }

    // Centered selection box
    Rectangle {
        id: wifiMainRect
        anchors.centerIn: parent
        width: 480
        height: 540
        radius: 16
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        clip: true
        opacity: 0.0
        scale: 0.96

        // Keyboard navigation
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Down) {
                event.accepted = true;
                root.selectedIndex = Math.min(root.selectedIndex + 1, networkListView.count - 1);
                networkListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
            } else if (event.key === Qt.Key_Up) {
                event.accepted = true;
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                networkListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true;
                if (root.selectedIndex >= 0 && root.selectedIndex < root.networkList.length) {
                    const selectedNet = root.networkList[root.selectedIndex];
                
                    if (root.expandedSsid === selectedNet.ssid) {
                        root.expandedSsid = "";
                    } else {
                        root.expandedSsid = selectedNet.ssid;
                        root.selectedSsid = selectedNet.ssid;
                        root.selectedSsidSecured = Boolean(selectedNet.secured);
                    }
                }
            } else if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                root.requestClose();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header with Title and Toggle Switch
            RowLayout {
                Layout.fillWidth: true
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Text {
                        text: "Available Networks"
                        color: root.theme.accentPrimary
                        font.pixelSize: 14
                        font.family: root.font
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }

                // Top Right Wi-Fi Toggle
                Rectangle {
                    width: 84
                    height: 26
                    radius: 6
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0

                        // "On" segment
                        Rectangle {
                            width: parent.width / 2
                            height: parent.height
                            radius: 4
                            color: root.wifiEnabled ? root.theme.bgSelected : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "On"
                                color: root.wifiEnabled 
                                    ? root.theme.accentPrimary 
                                    : root.theme.textMuted
                                font.pixelSize: 11
                                font.family: root.font
                                font.bold: root.wifiEnabled
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.wifiEnabled) {
                                        root.setWifiRequested(true);
                                    }
                                }
                            }
                        }

                        // "Off" segment
                        Rectangle {
                            width: parent.width / 2
                            height: parent.height
                            radius: 4
                            color: !root.wifiEnabled ? root.theme.bgSelected : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Off"
                                color: !root.wifiEnabled 
                                    ? root.theme.textPrimary 
                                    : root.theme.textMuted
                                font.pixelSize: 11
                                font.family: root.font
                                font.bold: !root.wifiEnabled
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.wifiEnabled) {
                                        root.setWifiRequested(false);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Error banner when connection fails
            Rectangle {
                visible: WifiService.lastError !== ""
                Layout.fillWidth: true
                implicitHeight: modalErrText.implicitHeight + 14
                radius: 8
                color: Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.14)
                border.color: Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.35)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 8
                    Text {
                        id: modalErrText
                        Layout.fillWidth: true
                        text: WifiService.lastError
                        color: root.theme.accentRed
                        font.pixelSize: 11
                        font.family: root.font
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        text: "✕"
                        color: root.theme.accentRed
                        font.pixelSize: 11
                        font.family: root.font
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WifiService.clearError()
                        }
                    }
                }
            }

            // Wi-Fi Network List
            ListView {
                id: networkListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.networkList
                clip: true
                spacing: 4
                focus: true 

                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
                displaced: Transition { NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic } }

                delegate: Rectangle {
                    id: networkDelegate
                    required property var modelData
                    required property int index

                    width: networkListView.width
                    readonly property bool isCurrent: modelData.ssid === root.currentSsid
                    readonly property bool isSaved: Boolean(WifiService.savedConnections[modelData.ssid])
                    readonly property bool needsPassword: Boolean(modelData.secured) && !isCurrent && !isSaved
                    readonly property bool isExpanded: root.expandedSsid === modelData.ssid
                    readonly property bool isSelected: root.selectedIndex === index

                    height: isExpanded ? (needsPassword ? 140 : 100) : 44
                    radius: 8
                    color: (isSelected || isExpanded) 
                        ? root.theme.bgSelected 
                        : (hoverArea.containsMouse 
                            ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) 
                            : "transparent")
                    clip: true
                    
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    property string enteredPassword: ""

                    onIsExpandedChanged: {
                        if (!isExpanded) {
                            enteredPassword = "";
                            networkListView.forceActiveFocus(); 
                        }
                    }

                    Rectangle {
                        width: 3
                        height: 24
                        radius: 2
                        color: root.theme.accentPrimary
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        visible: networkDelegate.isSelected
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: isExpanded ? 14 : 0
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        // Top Row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: isExpanded ? -1 : 44
                            spacing: 12

                            Text {
                                text: {
                                    if (modelData.signal > 80) return "󰤨";
                                    if (modelData.signal > 60) return "󰤥";
                                    if (modelData.signal > 40) return "󰤢";
                                    return "󰤟";
                                }
                                color: networkDelegate.isSelected 
                                    ? root.theme.accentPrimary 
                                    : root.theme.textPrimary
                                font.pixelSize: 16
                                font.family: root.font
                            }

                            Text {
                                text: modelData.ssid
                                color: networkDelegate.isSelected 
                                    ? root.theme.textPrimary 
                                    : root.theme.textSecondary
                                font.pixelSize: 13
                                font.family: root.font
                                font.bold: networkDelegate.isSelected
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            
                            Text {
                                text: "Connected"
                                color: root.theme.accentPrimary
                                font.pixelSize: 13
                                font.family: root.font
                                visible: networkDelegate.isCurrent
                            }

                            Text {
                                text: ""
                                visible: Boolean(modelData.secured) && !networkDelegate.isCurrent
                                color: root.theme.textMuted
                                font.pixelSize: 12
                                font.family: root.font
                            }
                        }

                        // Expanded Dropdown Area
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: networkDelegate.isExpanded
                            opacity: networkDelegate.isExpanded ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            spacing: 12

                            Loader {
                                id: pwdInputLoader
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                active: networkDelegate.isExpanded && networkDelegate.needsPassword
                                visible: active

                                sourceComponent: Rectangle {
                                    radius: 6
                                    color: root.theme.bgSurface
                                    border.color: pwdInput.activeFocus 
                                        ? root.theme.accentPrimary 
                                        : root.theme.bgBorder
                                    border.width: 1

                                    Component.onCompleted: pwdInput.forceActiveFocus()

                                    TextInput {
                                        id: pwdInput
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        color: root.theme.textPrimary
                                        font.pixelSize: 13
                                        font.family: root.font
                                        echoMode: TextInput.Password
                                        verticalAlignment: TextInput.AlignVCenter
                                        onTextChanged: networkDelegate.enteredPassword = text
                                        
                                        Keys.onEscapePressed: {
                                            if (pwdInput.text !== "") {
                                                pwdInput.text = "";
                                            } else {
                                                root.expandedSsid = "";
                                                networkListView.forceActiveFocus();
                                            }
                                        }
                                        
                                        Keys.onReturnPressed: {
                                            root.selectedSsid = modelData.ssid;
                                            root.selectedSsidSecured = Boolean(modelData.secured);
                                            root.connectToNetwork(pwdInput.text);
                                            root.expandedSsid = "";
                                            pwdInput.text = "";
                                            networkListView.forceActiveFocus();
                                        }
                                    }

                                    Text {
                                        text: "Password"
                                        color: root.theme.textMuted
                                        font.pixelSize: 13
                                        font.family: root.font
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        visible: pwdInput.text === ""
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                
                                Item { Layout.fillWidth: true } 

                                // Connect button (when not connected)
                                Rectangle {
                                    id: connectBtnRect
                                    visible: !networkDelegate.isCurrent
                                    width: WifiService.isConnecting && WifiService.connectingSsid === modelData.ssid ? 102 : 80
                                    height: 32
                                    radius: 6
                                    color: connectBtnMouse.containsMouse
                                        ? Qt.lighter(root.theme.accentPrimary, 1.12)
                                        : root.theme.accentPrimary
                                    border.color: "transparent"
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: (WifiService.isConnecting && WifiService.connectingSsid === modelData.ssid) ? "Connecting..." : "Connect"
                                        color: root.theme.bgBase
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: connectBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !WifiService.isConnecting
                                        onClicked: {
                                            root.selectedSsid = modelData.ssid;
                                            root.selectedSsidSecured = Boolean(modelData.secured);
                                            root.connectToNetwork(networkDelegate.enteredPassword);
                                            root.expandedSsid = "";
                                            networkDelegate.enteredPassword = "";
                                        }
                                    }
                                }

                                // Disconnect button (when connected)
                                Rectangle {
                                    visible: networkDelegate.isCurrent
                                    width: 90
                                    height: 32
                                    radius: 6
                                    color: disconnectBtnMouse.containsMouse
                                        ? root.theme.accentRed
                                        : Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.15)
                                    border.color: root.theme.accentRed
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: WifiService.isDisconnecting ? "Disconnecting..." : "Disconnect"
                                        color: disconnectBtnMouse.containsMouse
                                            ? root.theme.bgBase
                                            : root.theme.accentRed
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        id: disconnectBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !WifiService.isDisconnecting
                                        onClicked: {
                                            root.disconnectFromNetwork(modelData.ssid);
                                            root.expandedSsid = "";
                                        }
                                    }
                                }

                                // Cancel button
                                Rectangle {
                                    width: 80
                                    height: 32
                                    radius: 6
                                    color: root.theme.bgSurface
                                    border.color: root.theme.bgBorder
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cancel"
                                        color: root.theme.textPrimary
                                        font.family: root.font
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.expandedSsid = "";
                                            networkDelegate.enteredPassword = "";
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 44
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = networkDelegate.index
                        onClicked: {
                            networkListView.forceActiveFocus();
                            if (networkDelegate.isExpanded) {
                                root.expandedSsid = "";
                            } else {
                                root.expandedSsid = modelData.ssid;
                                root.selectedSsid = modelData.ssid;
                                root.selectedSsidSecured = Boolean(modelData.secured);
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Scanning for networks..."
                    color: root.theme.textMuted
                    font.pixelSize: 13
                    font.family: root.font
                    visible: WifiService.isScanning && root.wifiEnabled && root.networkList.length === 0
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "Wi-Fi is turned off"
                    color: root.theme.textMuted
                    font.pixelSize: 13
                    font.family: root.font
                    visible: !root.wifiEnabled
                }
            }

            // Footer Hints
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: -16
                Layout.rightMargin: -16
                Layout.bottomMargin: -16
                height: 32
                color: root.theme.bgSurface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16

                    Row {
                        spacing: 4
                        Text { text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Text { text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "select"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Text { text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
