import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "./Common"
import "./About"

Item {
    id: root
    property var theme
    property string font

    property string osName: "Linux"
    property string hostModel: "Generic System"
    property string cpuModel: "Unknown CPU"
    property string ramSize: "Unknown RAM"
    property string gpuModel: "Unknown GPU"
    property string diskSize: "Unknown Storage"
    property string kernelVer: "Unknown"
    property string uptimeStr: "Unknown"
    property string sessionType: "Wayland"
    property string archName: "x86_64"
    property string hostname: ""
    property string desktopName: ""

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/get_about_info.sh").toString().replace(/^file:\/\//, "")

    function copyText(textToCopy, toastMessage) {
        copyProc.command = ["wl-copy", textToCopy];
        copyProc.running = false;
        copyProc.running = true;
        toast.show(toastMessage);
    }

    function copyAllInfo() {
        const lines = [
            "OS: " + root.osName + " (" + root.archName + ")",
            "Host: " + root.hostModel + (root.hostname !== "" ? " (" + root.hostname + ")" : ""),
            "Kernel: " + root.kernelVer,
            "Uptime: " + root.uptimeStr,
            "Session: " + root.sessionType + (root.desktopName !== "" ? " (" + root.desktopName + ")" : ""),
            "CPU: " + root.cpuModel,
            "GPU: " + root.gpuModel,
            "Memory: " + root.ramSize,
            "Disk: " + root.diskSize
        ];
        root.copyText(lines.join("\n"), "Copied system summary");
    }

    property string pendingHostname: ""

    Process {
        id: copyProc
    }

    Process {
        id: renameProc
        onExited: (exitCode) => {
            if (exitCode === 0 && root.pendingHostname !== "") {
                root.hostname = root.pendingHostname;
                toast.show("Device name updated to " + root.pendingHostname);
                sysInfoProc.running = false;
                sysInfoProc.running = true;
            } else {
                toast.show("Failed to update device name", true);
            }
            root.pendingHostname = "";
        }
    }

    Process {
        id: sysInfoProc
        command: [root.scriptPath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length >= 9) {
                    root.osName = lines[0].trim() || "Linux";
                    root.hostModel = lines[1].trim() || "Generic System";
                    root.cpuModel = lines[2].trim() || "Unknown CPU";
                    root.ramSize = lines[3].trim() || "Unknown RAM";
                    root.gpuModel = lines[4].trim() || "Unknown GPU";
                    root.diskSize = lines[5].trim() || "Unknown Storage";
                    root.kernelVer = lines[6].trim() || "Unknown";
                    root.uptimeStr = lines[7].trim() || "Unknown";
                    root.sessionType = lines[8].trim() || "Wayland";
                    if (lines.length >= 10) root.archName = lines[9].trim() || "x86_64";
                    if (lines.length >= 11) root.hostname = lines[10].trim() || "";
                    if (lines.length >= 12) root.desktopName = lines[11].trim() || "";
                }
            }
        }
    }

    Process {
        id: uptimeOnlyProc
        command: ["uptime", "-p"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const up = text.trim().replace(/^up\s+/, "");
                if (up) root.uptimeStr = up;
            }
        }
    }

    onVisibleChanged: {
        if (visible && !sysInfoProc.running) {
            sysInfoProc.running = true;
        }
    }
    Component.onCompleted: {
        if (visible && !sysInfoProc.running) {
            sysInfoProc.running = true;
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.visible
        onTriggered: {
            if (!uptimeOnlyProc.running) uptimeOnlyProc.running = true;
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: mainLayout.implicitHeight + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainLayout
            width: parent.width
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "About System"
                    font.family: root.font
                    font.pixelSize: Style.px(20)
                    font.bold: Style.boldHeadings
                    font.letterSpacing: Style.letterSpacing
                    font.hintingPreference: Style.fontHintingEnum
                    antialiasing: Style.fontAntialiasing
                    renderType: Style.fontRenderTypeEnum
                    color: root.theme.textPrimary
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                ActionButton {
                    iconText: "󰆏"
                    label: "Copy Info"
                    onClicked: root.copyAllInfo()
                }

                ActionButton {
                    iconText: "󰑐"
                    label: "Refresh"
                    onClicked: {
                        sysInfoProc.running = false;
                        sysInfoProc.running = true;
                        toast.show("System info refreshed");
                    }
                }
            }

            AboutSystemBadgeCard {
                theme: root.theme
                font: root.font
                hostname: root.hostname
                hostModel: root.hostModel
                onHostnameSubmitted: (newName) => {
                    root.pendingHostname = newName;
                    renameProc.command = ["hostnamectl", "set-hostname", newName];
                    renameProc.running = false;
                    renameProc.running = true;
                }
            }

            AboutDetailsCard {
                theme: root.theme
                font: root.font
                ramSize: root.ramSize
                cpuModel: root.cpuModel
                gpuModel: root.gpuModel
                diskSize: root.diskSize
                osName: root.osName
                archName: root.archName
                sessionType: root.sessionType
                desktopName: root.desktopName
                kernelVer: root.kernelVer
                uptimeStr: root.uptimeStr
                onRowCopied: (label, value) => root.copyText(value, "Copied " + label)
            }
        }
    }

    ToastBanner {
        id: toast
        theme: root.theme
        font: root.font
    }
}
