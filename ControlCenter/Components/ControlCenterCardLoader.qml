import QtQuick

Loader {
    id: loader

    required property string cardId
    required property var theme
    required property string font
    // Used by the "tiles" block: a run of individual tile modules placed in a panel
    property var tileIds: []
    property int panelIndex: -1
    property int blockStart: 0
    property real extraHeight: 0

    signal closeParentRequested()
    signal openWifiRequested()
    signal quickSettingsReady(var ref)
    signal brightnessSliderReady(var ref)

    active: true

    sourceComponent: {
        switch (loader.cardId) {
        case "connectivity":
        case "quickSettings":
        case "quickSettings2":
            return quickSettingsComp;
        case "tiles":
            return panelTilesComp;
        case "brightness":
            return brightnessComp;
        case "audio":
            return audioComp;
        case "media":
            return mediaComp;
        case "systemInfo":
            return systemInfoComp;
        case "cava":
            return cavaComp;
        case "weather":
            return weatherComp;
        case "quickApps":
            return quickAppsComp;
        case "notifications":
            return notificationsComp;
        default:
            return null;
        }
    }

    Component {
        id: quickSettingsComp
        QuickSettingsGrid {
            id: qsGrid
            mode: loader.cardId === "connectivity"
                ? "connectivity"
                : (loader.cardId === "quickSettings2" ? "tiles2" : "tiles")
            theme: loader.theme
            font: loader.font
            onCloseParentRequested: loader.closeParentRequested()
            onOpenWifiRequested: loader.openWifiRequested()
            Component.onCompleted: loader.quickSettingsReady(qsGrid)
        }
    }

    Component {
        id: panelTilesComp
        QuickSettingsGrid {
            id: tilesGrid
            mode: "panelTiles"
            tileIds: loader.tileIds
            panelIndex: loader.panelIndex
            blockStart: loader.blockStart
            extraHeight: loader.extraHeight
            theme: loader.theme
            font: loader.font
            onCloseParentRequested: loader.closeParentRequested()
            onOpenWifiRequested: loader.openWifiRequested()
            Component.onCompleted: loader.quickSettingsReady(tilesGrid)
        }
    }

    Component {
        id: brightnessComp
        BrightnessSlider {
            id: bSlider
            theme: loader.theme
            font: loader.font
            Component.onCompleted: loader.brightnessSliderReady(bSlider)
        }
    }

    Component {
        id: audioComp
        AudioSection { theme: loader.theme; font: loader.font }
    }

    Component {
        id: mediaComp
        MediaControl { theme: loader.theme; font: loader.font }
    }

    Component {
        id: systemInfoComp
        SystemInfoCard { theme: loader.theme; font: loader.font }
    }

    Component {
        id: cavaComp
        CavaCard { theme: loader.theme; font: loader.font }
    }

    Component {
        id: weatherComp
        WeatherCard { theme: loader.theme; font: loader.font }
    }

    Component {
        id: quickAppsComp
        QuickAppsCard {
            theme: loader.theme
            font: loader.font
            onCloseParentRequested: loader.closeParentRequested()
        }
    }

    Component {
        id: notificationsComp
        NotificationsCard { theme: loader.theme; font: loader.font }
    }
}
