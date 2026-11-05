import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../wallpaper"
import "./Components"
import "./Modules"
import "."

FocusScope {
    id: surfaceViewRoot

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property alias authBoxRef: authBox
    property bool isAuthenticating: false
    property string errorMessage: ""
    property bool capsLockOn: false
    property string keyboardLayout: "US"

    property real surfaceOpacity: LockscreenConfig.unlock_animation ? 0.0 : 1.0
    property real bgZoom: LockscreenConfig.unlock_animation ? 1.04 : 1.0
    property real blurMultiplier: 1.0
    property real modulesOpacity: LockscreenConfig.unlock_animation ? 0.0 : 1.0
    property real modulesScale: LockscreenConfig.unlock_animation ? 0.96 : 1.0
    property real successGlowOpacity: 0.0

    opacity: surfaceOpacity

    signal submitPassword(string password)

    focus: true
    anchors.fill: parent
    clip: true

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; from: 0.0; to: 1.0; duration: 280; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; from: 1.04; to: 1.0; duration: 420; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesOpacity"; from: 0.0; to: 1.0; duration: 320; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesScale"; from: 0.96; to: 1.0; duration: 360; easing.type: Easing.OutBack }
    }

    ParallelAnimation {
        id: unlockSuccessAnim
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; to: 1.12; duration: 520; easing.type: Easing.InOutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "blurMultiplier"; to: 0.0; duration: 420; easing.type: Easing.OutQuad }
        NumberAnimation { target: surfaceViewRoot; property: "modulesScale"; to: 1.08; duration: 420; easing.type: Easing.InCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesOpacity"; to: 0.0; duration: 320; easing.type: Easing.OutQuad }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "successGlowOpacity"; from: 0.0; to: 0.18; duration: 140; easing.type: Easing.OutQuad }
            NumberAnimation { target: surfaceViewRoot; property: "successGlowOpacity"; to: 0.0; duration: 380; easing.type: Easing.InCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 160 }
            NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; to: 0.0; duration: 360; easing.type: Easing.InOutCubic }
        }
    }

    function triggerShake() {
        authBox.triggerShake();
    }

    function triggerSuccess() {
        authBox.triggerSuccess();
        if (LockscreenConfig.unlock_animation) {
            enterAnim.stop();
            unlockSuccessAnim.stop();
            unlockSuccessAnim.start();
        }
    }

    function clearInput() {
        authBox.clear();
    }

    function focusInput() {
        authBox.focusInput();
    }

    Component.onCompleted: {
        forceActiveFocus();
        authBox.focusInput();
        if (LockscreenConfig.unlock_animation) {
            enterAnim.start();
        }
    }

    function calculateX(halign, posX, itemWidth) {
        const xOffset = Number(posX) || 0;
        if (halign === "left") {
            return xOffset;
        } else if (halign === "right") {
            return surfaceViewRoot.width - itemWidth + xOffset;
        } else {
            return (surfaceViewRoot.width - itemWidth) / 2 + xOffset;
        }
    }

    function calculateY(valign, posY, itemHeight) {
        const yOffset = Number(posY) || 0;
        if (valign === "top") {
            return -yOffset;
        } else if (valign === "bottom") {
            return surfaceViewRoot.height - itemHeight - yOffset;
        } else {
            return (surfaceViewRoot.height - itemHeight) / 2 - yOffset;
        }
    }

    // Capture click on background to refocus input
    MouseArea {
        anchors.fill: parent
        onClicked: {
            surfaceViewRoot.forceActiveFocus();
            authBox.focusInput();
        }
    }

    // Background Image with MultiEffect layer
    Image {
        id: bgImage
        anchors.fill: parent
        source: {
            const home = Quickshell.env("HOME") || "";
            const src = LockscreenConfig.background_source;
            if (src === "custom" && LockscreenConfig.background_custom_path !== "")
                return "file://" + LockscreenConfig.background_custom_path;
            if (src === "effects")
                return "file://" + home + "/.cache/quickshell/wallpaper_effects/wallpaper_modified.png";
            if (src === "screenshot")
                return "file:///tmp/lockscreen_screenshot.png";
            const cur = (typeof WallpaperService !== "undefined")
                ? (WallpaperService.currentWallpaper || WallpaperService.wallpaperA || "")
                : "";
            if (cur !== "") return "file://" + cur;
            return "file://" + home + "/.config/hypr/wallpaper_effects/.wallpaper_current";
        }
        fillMode: Image.PreserveAspectCrop
        smooth: true
        scale: surfaceViewRoot.bgZoom
        asynchronous: !LockscreenConfig.general_immediate_render
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: LockscreenConfig.blur_passes > 0
            blurMax: 64
            blur: Math.min(1.0, (LockscreenConfig.blur_size / 10.0) * Math.min(1.0, LockscreenConfig.blur_passes / 2.0)) * surfaceViewRoot.blurMultiplier
            contrast: LockscreenConfig.contrast - 1.0
            brightness: LockscreenConfig.brightness - 1.0
            saturation: LockscreenConfig.vibrancy
        }
    }

    // Dark tint overlay from theme
    Rectangle {
        anchors.fill: parent
        color: surfaceViewRoot.theme.bgOverlay
        opacity: surfaceViewRoot.blurMultiplier
    }

    // Subtle Accent Green Flash Overlay on Unlock Success
    Rectangle {
        anchors.fill: parent
        color: surfaceViewRoot.theme.accentGreen
        opacity: surfaceViewRoot.successGlowOpacity
        visible: opacity > 0
    }

    // Forward any typing anywhere on the screen straight to the password input
    Keys.forwardTo: [authBox]

    // Reactive Lockscreen Modules
    readonly property var currentModules: {
        const t = LockscreenConfig.refreshTrigger;
        return LockscreenConfig.modules;
    }

    readonly property bool hasAuthModule: {
        if (!currentModules) return false;
        for (let i = 0; i < currentModules.length; i++) {
            if (currentModules[i] && currentModules[i].type === "auth") return true;
        }
        return false;
    }

    Repeater {
        model: surfaceViewRoot.currentModules

        Item {
            id: modItem
            required property var modelData
            required property int index

            readonly property var mData: {
                const t = LockscreenConfig.refreshTrigger;
                const list = LockscreenConfig.modules;
                if (list && index >= 0 && index < list.length) return list[index];
                return modelData;
            }

            visible: mData && mData.enabled !== false && mData.type !== "auth"
            opacity: surfaceViewRoot.modulesOpacity
            scale: surfaceViewRoot.modulesScale

            width: host.implicitWidth
            height: host.implicitHeight

            readonly property int _trigger: LockscreenConfig.refreshTrigger
            readonly property string _halign: mData ? (mData.halign || "center") : "center"
            readonly property string _valign: mData ? (mData.valign || "center") : "center"
            readonly property real _posX: mData ? (mData.position_x !== undefined ? mData.position_x : 0) : 0
            readonly property real _posY: mData ? (mData.position_y !== undefined ? mData.position_y : 0) : 0

            x: (_trigger >= 0 && mData) ? Math.round(surfaceViewRoot.calculateX(_halign, _posX, width)) : 0
            y: (_trigger >= 0 && mData) ? Math.round(surfaceViewRoot.calculateY(_valign, _posY, height)) : 0

            LockModuleHost {
                id: host
                theme: surfaceViewRoot.theme
                font: surfaceViewRoot.font
                moduleData: modItem.mData
                previewMode: false
            }
        }
    }

    // Centered / Cartesian Positioned Password Input Box
    LockAuthBox {
        id: authBox
        theme: surfaceViewRoot.theme
        font: surfaceViewRoot.font
        isAuthenticating: surfaceViewRoot.isAuthenticating
        errorMessage: surfaceViewRoot.errorMessage
        capsLockOn: surfaceViewRoot.capsLockOn
        visible: true
        width: implicitWidth
        height: implicitHeight

        readonly property var authMod: {
            if (!surfaceViewRoot.currentModules) return null;
            for (let i = 0; i < surfaceViewRoot.currentModules.length; i++) {
                let m = surfaceViewRoot.currentModules[i];
                if (m && m.type === "auth") return m;
            }
            return null;
        }

        readonly property int _trigger: LockscreenConfig.refreshTrigger
        readonly property string targetHAlign: authMod ? (authMod.halign || "center") : LockscreenConfig.input_halign
        readonly property string targetVAlign: authMod ? (authMod.valign || "center") : LockscreenConfig.input_valign
        readonly property real targetPosX: authMod ? (authMod.position_x !== undefined ? authMod.position_x : 0) : LockscreenConfig.input_pos_x
        readonly property real targetPosY: authMod ? (authMod.position_y !== undefined ? authMod.position_y : 0) : LockscreenConfig.input_pos_y

        x: (_trigger >= 0) ? Math.round(surfaceViewRoot.calculateX(targetHAlign, targetPosX, width)) : 0
        y: (_trigger >= 0) ? Math.round(surfaceViewRoot.calculateY(targetVAlign, targetPosY, height)) : 0

        onSubmit: pwd => surfaceViewRoot.submitPassword(pwd)
    }
}
