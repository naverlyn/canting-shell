import QtQuick
import ".."

Item {
    id: hostRoot

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    readonly property string modType: (moduleData && moduleData.type) ? moduleData.type : ""

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0

    Loader {
        id: loader
        anchors.fill: parent

        sourceComponent: {
            switch(hostRoot.modType) {
                case "clock": return clockComp;
                case "auth": return authComp;
                case "statusInfo": return statusInfoComp;
                case "media": return mediaComp;
                case "weather": return weatherComp;
                case "cpu": return cpuComp;
                case "memory": return memoryComp;
                case "disk": return diskComp;
                case "battery": return batteryComp;
                case "systemInfo": return systemInfoComp;
                case "uptime": return uptimeComp;
                case "layout": return layoutComp;
                case "customText": return customTextComp;
                default: return fallbackComp;
            }
        }
    }

    Component {
        id: clockComp
        ClockModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: mediaComp
        MediaModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: weatherComp
        WeatherModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: cpuComp
        CpuModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: memoryComp
        MemoryModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: diskComp
        DiskModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: batteryComp
        BatteryModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: systemInfoComp
        SystemInfoModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: uptimeComp
        UptimeModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: layoutComp
        LayoutModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: customTextComp
        CustomTextModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: authComp
        AuthModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: statusInfoComp
        StatusInfoModule {
            theme: hostRoot.theme
            font: hostRoot.font
            moduleData: hostRoot.moduleData
            previewMode: hostRoot.previewMode
            scaleFactor: hostRoot.scaleFactor
        }
    }

    Component {
        id: fallbackComp
        Text {
            text: hostRoot.moduleData ? (hostRoot.moduleData.name || hostRoot.modType) : ""
            font.family: hostRoot.font
            font.pixelSize: Math.max(9, Math.round(13 * hostRoot.scaleFactor))
            color: hostRoot.theme.textPrimary
        }
    }
}
