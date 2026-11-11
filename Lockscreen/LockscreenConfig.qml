pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath: Qt.resolvedUrl("../lockscreen_config.json").toString().replace(/^file:\/\//, "")

    property string background_source: "wallpaper"
    property string background_custom_path: ""
    property int blur_passes: 2
    property int blur_size: 3
    property real contrast: 1.25
    property real brightness: 0.8
    property real vibrancy: 0.21
    property bool general_immediate_render: true
    property bool unlock_animation: true
    property string animation_style: "default"

    property string clock_format: "24h"
    property int clock_font_size: 90
    property bool show_date: true
    property bool show_user: true
    property bool show_layout: true
    property bool show_uptime: true
    property bool show_weather: true
    property bool show_media: true

    readonly property alias showUser: root.show_user
    readonly property alias showDate: root.show_date
    readonly property alias showWeather: root.show_weather
    readonly property alias showUptime: root.show_uptime
    readonly property alias showLayout: root.show_layout
    readonly property alias showMedia: root.show_media

    property int input_width: 300
    property int input_height: 56
    property int input_outline_thickness: 3
    property string input_placeholder: "Password"
    property int input_pos_x: 0
    property int input_pos_y: 0
    property string input_halign: "center"
    property string input_valign: "center"
    property string input_outer_color: "$accent"
    property string input_inner_color: "$surface0"
    property string input_font_color: "$text"

    // Master list of available lockscreen building block modules
    readonly property var availableModuleDefs: [
        { type: "auth",       name: "User & Password",   icon: "󰌾", desc: "User profile avatar, username, and password entry" },
        { type: "statusInfo", name: "Keyboard & Uptime", icon: "󰌌", desc: "Keyboard layout and system uptime pill" },
        { type: "clock",      name: "Clock & Date",      icon: "", desc: "Large digital clock with day and date" },
        { type: "weather",    name: "Weather",           icon: "󰖐", desc: "Live weather conditions, temperature and summary" },
        { type: "media",         name: "Media Player",      icon: "󰝚", desc: "Floating MPRIS audio player with controls" },
        { type: "notifications", name: "Notifications",     icon: "󰂚", desc: "Live notification cards and unread alerts stack" },
        { type: "cpu",           name: "CPU Usage",         icon: "󰻠", desc: "Live processor utilization percentage & bar" },
        { type: "memory",     name: "Memory (RAM)",      icon: "󰍛", desc: "Live RAM utilization percentage & bar" },
        { type: "disk",       name: "Disk Storage",      icon: "", desc: "Root filesystem storage utilization" },
        { type: "battery",    name: "Battery Status",    icon: "󰁹", desc: "Battery charge percentage & power status" },
        { type: "systemInfo", name: "System Resources",  icon: "󰒋", desc: "Consolidated CPU, RAM, Disk and Temp card" },
        { type: "uptime",     name: "System Uptime",     icon: "󰅐", desc: "System boot duration readout" },
        { type: "layout",     name: "Keyboard Layout",   icon: "󰌌", desc: "Current active keyboard layout indicator" },
        { type: "customText", name: "Custom Text / Cmd", icon: "󰆍", desc: "Custom formatted text or shell script runner" }
    ]

    readonly property var defaultModules: [
        { id: "clock_1", type: "clock", name: "Clock & Date", enabled: true, halign: "left", valign: "top", position_x: 48, position_y: -44, color: "$text", fontSize: 90, clockFormat: "24h", showDate: true, showCard: false },
        { id: "auth_1", type: "auth", name: "User & Password", enabled: true, halign: "center", valign: "center", position_x: 0, position_y: -85, color: "$accent" },
        { id: "weather_1", type: "weather", name: "Weather", enabled: true, halign: "left", valign: "bottom", position_x: 36, position_y: 32, color: "$color10", displayMode: "detailed", showCard: true },
        { id: "media_1", type: "media", name: "Media Player", enabled: true, halign: "center", valign: "bottom", position_x: 0, position_y: 32, color: "$accent", showCard: true },
        { id: "status_1", type: "statusInfo", name: "Keyboard & Uptime", enabled: true, halign: "right", valign: "bottom", position_x: -36, position_y: 32, color: "$accent", showCard: true }
    ]

    property var modules: []
    property alias text_blocks: root.modules // compatibility alias
    property int refreshTrigger: 0

    property bool _loaded: false
    property bool _savePending: false
    property string _lastSavedJson: ""
    signal configChanged()

    function getDefForType(mType) {
        for (let i = 0; i < root.availableModuleDefs.length; i++) {
            if (root.availableModuleDefs[i].type === mType)
                return root.availableModuleDefs[i];
        }
        return { type: mType, name: mType, icon: "󰆍", desc: "" };
    }

    function addModule(mType, overrides) {
        const def = getDefForType(mType);
        let list = root.modules ? [...root.modules] : [];
        let newId = mType + "_" + Date.now();

        let rightBottomCount = 0;
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].halign === "right" && list[i].valign === "bottom") {
                rightBottomCount++;
            }
        }
        let defaultY = 32;
        if (rightBottomCount > 0 && mType !== "clock" && mType !== "media" && mType !== "auth") {
            defaultY = 32 + (rightBottomCount * 56);
        }

        let newMod = {
            id: newId,
            index: list.length,
            type: mType,
            name: def.name,
            enabled: true,
            showCard: (mType !== "clock" && mType !== "auth" && mType !== "customText"),
            halign: (mType === "clock") ? "left" : ((mType === "media" || mType === "auth") ? "center" : "right"),
            valign: (mType === "clock") ? "top" : ((mType === "auth") ? "center" : "bottom"),
            position_x: (mType === "clock") ? 48 : ((mType === "media" || mType === "auth") ? 0 : -36),
            position_y: (mType === "clock") ? -44 : ((mType === "auth") ? 0 : defaultY),
            color: (mType === "clock") ? "$text" : "$accent",
            fontSize: (mType === "clock") ? 90 : 13
        };

        if (mType === "clock") {
            newMod.clockFormat = "24h";
            newMod.showDate = true;
        } else if (mType === "weather") {
            newMod.displayMode = "detailed";
        } else if (mType === "customText") {
            newMod.text = "Hello World";
            newMod.cmd = "";
            newMod.interval = 5000;
        } else if (mType === "statusInfo") {
            newMod.fontSize = 13;
        } else if (mType === "auth") {
            newMod.halign = "center";
            newMod.valign = "center";
            newMod.position_x = 0;
            newMod.position_y = -85;
        } else if (mType === "notifications") {
            newMod.halign = "left";
            newMod.valign = "center";
            newMod.position_x = 36;
            newMod.position_y = 0;
            newMod.displayMode = "full";
            newMod.maxVisible = 3;
            newMod.showContent = true;
            newMod.hideWhenEmpty = false;
        }

        if (overrides && typeof overrides === "object") {
            Object.assign(newMod, overrides);
        }

        list.push(newMod);
        root.modules = list;
        root.refreshTrigger++;
        root.saveConfig();
        root.configChanged();
        return list.length - 1;
    }

    // Alias for legacy addBlock
    function addBlock(customBlock) {
        return addModule((customBlock && customBlock.type) ? customBlock.type : "customText");
    }

    function updateModule(idx, payload) {
        if (!root.modules || idx < 0 || idx >= root.modules.length) return;
        let list = [...root.modules];
        list[idx] = Object.assign({}, list[idx], payload);
        if (list[idx].type === "clock") {
            if (payload.clockFormat !== undefined) root.clock_format = payload.clockFormat;
            if (payload.fontSize !== undefined) root.clock_font_size = Number(payload.fontSize) || 90;
            if (payload.showDate !== undefined) root.show_date = Boolean(payload.showDate);
        }
        root.modules = list;
        root.refreshTrigger++;
        root.saveConfig();
        root.configChanged();
    }

    // Alias for legacy updateBlock
    function updateBlock(idx, payload) {
        updateModule(idx, payload);
    }

    function deleteModule(idxOrId) {
        if (!root.modules || root.modules.length === 0) return;
        let list = [...root.modules];
        let targetIdx = -1;
        if (typeof idxOrId === "number") {
            targetIdx = idxOrId;
        } else if (typeof idxOrId === "string") {
            for (let i = 0; i < list.length; i++) {
                if (list[i] && (list[i].id === idxOrId || list[i].type === idxOrId)) {
                    targetIdx = i;
                    break;
                }
            }
        }
        if (targetIdx < 0 || targetIdx >= list.length) return;
        list.splice(targetIdx, 1);
        for (let i = 0; i < list.length; i++) {
            list[i].index = i;
        }
        root.modules = list;
        root.refreshTrigger++;
        root.saveConfig();
        root.configChanged();
    }

    // Alias for legacy deleteBlock
    function deleteBlock(idx) {
        deleteModule(idx);
    }

    function updatePositions(payload) {
        if (!payload || !Array.isArray(payload)) return;
        let list = root.modules ? [...root.modules] : [];
        for (let i = 0; i < payload.length; i++) {
            let item = payload[i];
            if (item.index === -1) {
                root.input_pos_x = Number(item.position_x) || 0;
                root.input_pos_y = Number(item.position_y) || 0;
                if (item.halign) root.input_halign = item.halign;
                if (item.valign) root.input_valign = item.valign;
            } else {
                let targetIdx = -1;
                if (item.id) {
                    for (let j = 0; j < list.length; j++) {
                        if (list[j] && list[j].id === item.id) {
                            targetIdx = j;
                            break;
                        }
                    }
                }
                if (targetIdx === -1 && item.index >= 0 && item.index < list.length) {
                    targetIdx = item.index;
                }
                if (targetIdx >= 0 && targetIdx < list.length) {
                    list[targetIdx] = Object.assign({}, list[targetIdx], {
                        position_x: Number(item.position_x) || 0,
                        position_y: Number(item.position_y) || 0,
                        halign: item.halign || list[targetIdx].halign,
                        valign: item.valign || list[targetIdx].valign
                    });
                }
            }
        }
        root.modules = list;
        root.refreshTrigger++;
        saveDebounceTimer.stop();
        root.doWriteConfig();
        root.configChanged();
    }

    Timer {
        id: saveDebounceTimer
        interval: 150
        repeat: false
        onTriggered: root.doWriteConfig()
    }

    function saveConfig() {
        if (!root._loaded) return;
        saveDebounceTimer.restart();
    }

    function doWriteConfig() {
        if (saveProcess.running) {
            root._savePending = true;
            return;
        }
        root._savePending = false;

        const data = {
            background_source: root.background_source,
            background_custom_path: root.background_custom_path,
            blur_passes: root.blur_passes,
            blur_size: root.blur_size,
            contrast: root.contrast,
            brightness: root.brightness,
            vibrancy: root.vibrancy,
            general_immediate_render: root.general_immediate_render,
            unlock_animation: root.unlock_animation,
            animation_style: root.animation_style,
            clock_format: root.clock_format,
            clock_font_size: root.clock_font_size,
            show_date: root.show_date,
            show_user: root.show_user,
            show_layout: root.show_layout,
            show_uptime: root.show_uptime,
            show_weather: root.show_weather,
            show_media: root.show_media,
            input_width: root.input_width,
            input_height: root.input_height,
            input_outline_thickness: root.input_outline_thickness,
            input_placeholder: root.input_placeholder,
            input_pos_x: root.input_pos_x,
            input_pos_y: root.input_pos_y,
            input_halign: root.input_halign,
            input_valign: root.input_valign,
            input_outer_color: root.input_outer_color,
            input_inner_color: root.input_inner_color,
            input_font_color: root.input_font_color,
            modules: root.modules || root.defaultModules
        };
        const jsonStr = JSON.stringify(data, null, 2);
        root._lastSavedJson = jsonStr;
        saveProcess.command = [
            "python3", "-c",
            "import os, sys; p = sys.argv[1]; tmp = p + '.tmp'; open(tmp, 'w').write(sys.argv[2] + '\\n'); os.replace(tmp, p)",
            root.configPath,
            jsonStr
        ];
        saveProcess.running = true;
    }

    function resetDefaults() {
        root.background_source = "wallpaper";
        root.background_custom_path = "";
        root.blur_passes = 2;
        root.blur_size = 3;
        root.contrast = 1.25;
        root.brightness = 0.8;
        root.vibrancy = 0.21;
        root.general_immediate_render = true;
        root.unlock_animation = true;
        root.animation_style = "default";
        root.clock_format = "24h";
        root.clock_font_size = 90;
        root.show_date = true;
        root.show_user = true;
        root.show_layout = true;
        root.show_uptime = true;
        root.show_weather = true;
        root.show_media = true;
        root.input_width = 300;
        root.input_height = 56;
        root.input_outline_thickness = 3;
        root.input_placeholder = "Password";
        root.input_pos_x = 0;
        root.input_pos_y = 0;
        root.input_halign = "center";
        root.input_valign = "center";
        root.input_outer_color = "$accent";
        root.input_inner_color = "$surface0";
        root.input_font_color = "$text";
        root.modules = JSON.parse(JSON.stringify(root.defaultModules));
        root.refreshTrigger++;
        root.saveConfig();
        root.configChanged();
    }

    function applyConfig(cfg) {
        if (!cfg) return;
        if (cfg.background_source !== undefined) root.background_source = cfg.background_source;
        if (cfg.background_custom_path !== undefined) root.background_custom_path = cfg.background_custom_path;
        if (cfg.blur_passes !== undefined) root.blur_passes = Number(cfg.blur_passes) || 2;
        if (cfg.blur_size !== undefined) root.blur_size = Number(cfg.blur_size) || 3;
        if (cfg.contrast !== undefined) root.contrast = Number(cfg.contrast) || 1.25;
        if (cfg.brightness !== undefined) root.brightness = Number(cfg.brightness) || 0.8;
        if (cfg.vibrancy !== undefined) root.vibrancy = Number(cfg.vibrancy) || 0.21;
        if (cfg.general_immediate_render !== undefined) root.general_immediate_render = Boolean(cfg.general_immediate_render);
        if (cfg.unlock_animation !== undefined) root.unlock_animation = Boolean(cfg.unlock_animation);
        if (cfg.animation_style !== undefined) root.animation_style = String(cfg.animation_style) || "default";
        if (cfg.clock_format !== undefined) root.clock_format = cfg.clock_format;
        if (cfg.clock_font_size !== undefined) root.clock_font_size = Number(cfg.clock_font_size) || 90;
        if (cfg.show_date !== undefined) root.show_date = Boolean(cfg.show_date);
        if (cfg.show_user !== undefined) root.show_user = Boolean(cfg.show_user);
        if (cfg.show_layout !== undefined) root.show_layout = Boolean(cfg.show_layout);
        if (cfg.show_uptime !== undefined) root.show_uptime = Boolean(cfg.show_uptime);
        if (cfg.show_weather !== undefined) root.show_weather = Boolean(cfg.show_weather);
        if (cfg.show_media !== undefined) root.show_media = Boolean(cfg.show_media);
        if (cfg.input_width !== undefined) root.input_width = Number(cfg.input_width) || 300;
        if (cfg.input_height !== undefined) root.input_height = Number(cfg.input_height) || 56;
        if (cfg.input_outline_thickness !== undefined) root.input_outline_thickness = Number(cfg.input_outline_thickness) || 3;
        if (cfg.input_placeholder !== undefined) root.input_placeholder = cfg.input_placeholder;
        if (cfg.input_pos_x !== undefined) root.input_pos_x = Number(cfg.input_pos_x) || 0;
        if (cfg.input_pos_y !== undefined) root.input_pos_y = Number(cfg.input_pos_y) || 0;
        if (cfg.input_halign !== undefined) root.input_halign = cfg.input_halign;
        if (cfg.input_valign !== undefined) root.input_valign = cfg.input_valign;
        if (cfg.input_outer_color !== undefined) root.input_outer_color = cfg.input_outer_color;
        if (cfg.input_inner_color !== undefined) root.input_inner_color = cfg.input_inner_color;
        if (cfg.input_font_color !== undefined) root.input_font_color = cfg.input_font_color;

        if (cfg.modules !== undefined && Array.isArray(cfg.modules) && cfg.modules.length > 0) {
            root.modules = cfg.modules;
        } else if (cfg.text_blocks !== undefined && Array.isArray(cfg.text_blocks) && cfg.text_blocks.length > 0) {
            // Migrate legacy text_blocks to modern modules
            let migrated = [];
            for (let i = 0; i < cfg.text_blocks.length; i++) {
                let tb = cfg.text_blocks[i];
                let mType = "customText";
                let nLow = String(tb.name || "").toLowerCase();
                let rLow = String(tb.raw_text || "").toLowerCase();
                if (nLow === "time" || rLow.includes("$time")) mType = "clock";
                else if (nLow === "date" || rLow.includes("date +")) mType = "clock";
                else if (nLow === "weather" || rLow.includes("weather")) mType = "weather";
                else if (nLow === "uptime" || rLow.includes("uptime")) mType = "uptime";
                else if (nLow === "layout" || rLow.includes("$layout")) mType = "layout";
                else if (nLow === "cpu") mType = "cpu";
                else if (nLow === "memory" || nLow === "ram") mType = "memory";
                else if (nLow === "disk") mType = "disk";
                else if (nLow === "battery") mType = "battery";
                else if (nLow === "media") mType = "media";
                else if (nLow === "notifications" || nLow === "notification") mType = "notifications";

                migrated.push({
                    id: tb.id || (mType + "_" + (i + 1)),
                    index: i,
                    type: mType,
                    name: tb.name || mType,
                    enabled: tb.enabled !== false,
                    halign: tb.halign || "center",
                    valign: tb.valign || "center",
                    position_x: tb.position_x || 0,
                    position_y: tb.position_y || 0,
                    color: tb.color || "$text",
                    fontSize: tb.font_size || 14,
                    clockFormat: root.clock_format,
                    showDate: root.show_date,
                    cmd: tb.cmd_body || "",
                    text: tb.raw_text || ""
                });
            }
            root.modules = migrated;
        } else {
            root.modules = JSON.parse(JSON.stringify(root.defaultModules));
        }

        root.refreshTrigger++;
    }

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onFileChanged: configFile.reload()
        onTextChanged: {
            const raw = configFile.text();
            if (!raw) {
                root._loaded = true;
                return;
            }
            if (root._lastSavedJson !== "" && raw.trim() === root._lastSavedJson.trim()) {
                root._loaded = true;
                return;
            }
            try {
                const parsed = JSON.parse(raw);
                root.applyConfig(parsed);
                root.configChanged();
            } catch(e) {
                console.error("Failed to parse lockscreen_config.json:", e);
            } finally {
                root._loaded = true;
            }
        }
    }

    Process {
        id: saveProcess
        running: false
        onExited: (exitCode) => {
            if (root._savePending) {
                root._savePending = false;
                root.doWriteConfig();
            }
            root.configChanged();
        }
    }

    Component.onCompleted: {
        root._loaded = true;
    }
}
