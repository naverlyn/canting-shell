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
    property string font: (surfaceViewRoot.theme && surfaceViewRoot.theme.monoFont) ? surfaceViewRoot.theme.monoFont : "JetBrainsMono Nerd Font"
    property alias authBoxRef: authBox
    property bool isAuthenticating: false
    property string errorMessage: ""
    property bool capsLockOn: false
    property string keyboardLayout: "US"

    readonly property string animStyle: LockscreenConfig.animation_style || "default"
    readonly property bool animEnabled: Boolean(LockscreenConfig.unlock_animation)

    property real surfaceOpacity: animEnabled ? 0.0 : 1.0
    property real bgZoom: animEnabled ? 1.04 : 1.0
    property real blurMultiplier: 1.0
    property real modulesOpacity: animEnabled ? 0.0 : 1.0
    property real modulesScale: animEnabled ? 0.96 : 1.0
    property real modulesBlur: 0.0
    property real successGlowOpacity: 0.0

    // Staggered / Directional / Curtain / Portal animation properties
    property real authOffsetX: 0.0
    property real authOffsetY: 0.0
    property real authExtraScale: 1.0
    property real curtainProgress: 0.0
    property real curtainSplitOffset: 0.0
    property real curtainSeamOpacity: 0.0
    property real curtainSeamWidth: 0.0
    property real depthFlashOpacity: 0.0
    property real portalPullProgress: 0.0
    property real portalRingRadius: 0.0
    property real portalRingOpacity: 0.0
    property real portalInnerRadius: 0.0
    property real portalInnerOpacity: 0.0

    readonly property real maxScreenSpan: Math.max(1920, Math.sqrt(width * width + height * height))
    readonly property real portalOriginX: authBox.x + authBox.width / 2
    readonly property real portalOriginY: authBox.y + authBox.height / 2

    signal submitPassword(string password)
    signal staggeredEnterTriggered()
    signal staggeredExitTriggered()

    opacity: surfaceOpacity
    focus: true
    anchors.fill: parent
    clip: true

    // =========================================================================
    // 1. DEFAULT ANIMATION (Classic fade, subtle zoom, and shockwave ripple)
    // =========================================================================
    ParallelAnimation {
        id: enterDefaultAnim
        NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; from: 0.0; to: 1.0; duration: 280; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; from: 1.04; to: 1.0; duration: 420; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesOpacity"; from: 0.0; to: 1.0; duration: 320; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesScale"; from: 0.96; to: 1.0; duration: 360; easing.type: Easing.OutBack }
    }

    ParallelAnimation {
        id: unlockDefaultAnim
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

    // =========================================================================
    // 2. STAGGERED CASCADE ANIMATION (Edge fly-in with spring physics)
    // =========================================================================
    ParallelAnimation {
        id: enterStaggeredAnim
        NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; from: 0.0; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; from: 1.08; to: 1.0; duration: 480; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "blurMultiplier"; from: 0.0; to: 1.0; duration: 420; easing.type: Easing.OutCubic }
        SequentialAnimation {
            PauseAnimation { duration: 60 }
            ParallelAnimation {
                NumberAnimation { target: surfaceViewRoot; property: "authOffsetY"; from: 70; to: 0; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.35 }
                NumberAnimation { target: surfaceViewRoot; property: "authExtraScale"; from: 0.86; to: 1.0; duration: 380; easing.type: Easing.OutBack }
            }
        }
    }

    ParallelAnimation {
        id: unlockStaggeredAnim
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; to: 1.10; duration: 500; easing.type: Easing.InOutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "blurMultiplier"; to: 0.0; duration: 400; easing.type: Easing.OutQuad }
        NumberAnimation { target: surfaceViewRoot; property: "authOffsetY"; to: -85; duration: 380; easing.type: Easing.InBack; easing.overshoot: 1.25 }
        NumberAnimation { target: surfaceViewRoot; property: "authExtraScale"; to: 0.88; duration: 360; easing.type: Easing.InCubic }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "successGlowOpacity"; from: 0.0; to: 0.15; duration: 120; easing.type: Easing.OutQuad }
            NumberAnimation { target: surfaceViewRoot; property: "successGlowOpacity"; to: 0.0; duration: 360; easing.type: Easing.InCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 190 }
            NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; to: 0.0; duration: 340; easing.type: Easing.InOutCubic }
        }
    }

    // =========================================================================
    // 3. CINEMA CURTAIN ANIMATION (Vertical shutter split & glowing laser seam)
    // =========================================================================
    ParallelAnimation {
        id: enterCurtainAnim
        NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; from: 0.0; to: 1.0; duration: 140; easing.type: Easing.OutQuad }
        NumberAnimation { target: surfaceViewRoot; property: "curtainProgress"; from: 1.0; to: 0.0; duration: 480; easing.type: Easing.OutExpo }
        NumberAnimation { target: surfaceViewRoot; property: "curtainSplitOffset"; from: 1.0; to: 0.0; duration: 460; easing.type: Easing.OutQuart }
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; from: 1.06; to: 1.0; duration: 480; easing.type: Easing.OutQuart }
        NumberAnimation { target: surfaceViewRoot; property: "modulesOpacity"; from: 0.0; to: 1.0; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesScale"; from: 0.94; to: 1.0; duration: 420; easing.type: Easing.OutQuart }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "curtainSeamWidth"; from: 0.2; to: 1.0; duration: 180; easing.type: Easing.OutQuad }
            NumberAnimation { target: surfaceViewRoot; property: "curtainSeamWidth"; to: 0.0; duration: 300; easing.type: Easing.InQuad }
        }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "curtainSeamOpacity"; from: 0.95; to: 0.0; duration: 420; easing.type: Easing.OutCubic }
        }
    }

    ParallelAnimation {
        id: unlockCurtainAnim
        NumberAnimation { target: surfaceViewRoot; property: "curtainSplitOffset"; from: 0.0; to: 1.25; duration: 460; easing.type: Easing.InQuart }
        NumberAnimation { target: surfaceViewRoot; property: "blurMultiplier"; to: 0.0; duration: 380; easing.type: Easing.OutQuad }
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; to: 1.08; duration: 480; easing.type: Easing.InOutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesOpacity"; to: 0.0; duration: 320; easing.type: Easing.InQuad }
        NumberAnimation { target: surfaceViewRoot; property: "authOffsetY"; to: -55; duration: 380; easing.type: Easing.InQuart }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "curtainSeamWidth"; from: 0.0; to: 1.0; duration: 140; easing.type: Easing.OutExpo }
            NumberAnimation { target: surfaceViewRoot; property: "curtainSeamWidth"; to: 0.3; duration: 360; easing.type: Easing.InQuad }
        }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "curtainSeamOpacity"; from: 0.0; to: 1.0; duration: 110; easing.type: Easing.OutQuad }
            NumberAnimation { target: surfaceViewRoot; property: "curtainSeamOpacity"; to: 0.0; duration: 380; easing.type: Easing.InCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 150 }
            NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; to: 0.0; duration: 360; easing.type: Easing.InOutQuart }
        }
    }

    // =========================================================================
    // 4. ZOOM & DEPTH OF FIELD ANIMATION (Camera lens rack focus & hyper-zoom)
    // =========================================================================
    ParallelAnimation {
        id: enterDepthAnim
        NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; from: 0.0; to: 1.0; duration: 260; easing.type: Easing.OutQuad }
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; from: 1.28; to: 1.0; duration: 540; easing.type: Easing.OutExpo }
        NumberAnimation { target: surfaceViewRoot; property: "blurMultiplier"; from: 0.0; to: 1.0; duration: 480; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesScale"; from: 1.26; to: 1.0; duration: 480; easing.type: Easing.OutExpo }
        NumberAnimation { target: surfaceViewRoot; property: "modulesOpacity"; from: 0.0; to: 1.0; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesBlur"; from: 0.85; to: 0.0; duration: 440; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "authExtraScale"; from: 1.24; to: 1.0; duration: 480; easing.type: Easing.OutExpo }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "depthFlashOpacity"; from: 0.35; to: 0.0; duration: 420; easing.type: Easing.OutCubic }
        }
    }

    ParallelAnimation {
        id: unlockDepthAnim
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; to: 1.32; duration: 520; easing.type: Easing.InOutExpo }
        NumberAnimation { target: surfaceViewRoot; property: "blurMultiplier"; to: 0.0; duration: 360; easing.type: Easing.OutQuad }
        NumberAnimation { target: surfaceViewRoot; property: "modulesScale"; to: 1.38; duration: 420; easing.type: Easing.InCubic }
        NumberAnimation { target: surfaceViewRoot; property: "modulesBlur"; to: 0.9; duration: 360; easing.type: Easing.InQuad }
        NumberAnimation { target: surfaceViewRoot; property: "modulesOpacity"; to: 0.0; duration: 300; easing.type: Easing.InQuad }
        NumberAnimation { target: surfaceViewRoot; property: "authExtraScale"; to: 1.35; duration: 420; easing.type: Easing.InCubic }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "depthFlashOpacity"; from: 0.0; to: 0.24; duration: 150; easing.type: Easing.OutQuad }
            NumberAnimation { target: surfaceViewRoot; property: "depthFlashOpacity"; to: 0.0; duration: 360; easing.type: Easing.InCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 140 }
            NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; to: 0.0; duration: 370; easing.type: Easing.InOutCubic }
        }
    }

    // =========================================================================
    // 5. PORTAL IRIS ANIMATION (Radial shockwave & vortex pull from Auth Box)
    // =========================================================================
    ParallelAnimation {
        id: enterPortalAnim
        NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; from: 0.0; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; from: 1.10; to: 1.0; duration: 480; easing.type: Easing.OutQuart }
        NumberAnimation { target: surfaceViewRoot; property: "blurMultiplier"; from: 0.0; to: 1.0; duration: 420; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "portalPullProgress"; from: 0.42; to: 0.0; duration: 480; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
        NumberAnimation { target: surfaceViewRoot; property: "modulesScale"; from: 0.72; to: 1.0; duration: 460; easing.type: Easing.OutBack }
        NumberAnimation { target: surfaceViewRoot; property: "modulesOpacity"; from: 0.0; to: 1.0; duration: 320; easing.type: Easing.OutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "authExtraScale"; from: 0.65; to: 1.0; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        NumberAnimation { target: surfaceViewRoot; property: "portalRingRadius"; from: 48; to: surfaceViewRoot.maxScreenSpan; duration: 540; easing.type: Easing.OutQuart }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "portalRingOpacity"; from: 0.9; to: 0.0; duration: 520; easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: surfaceViewRoot; property: "portalInnerRadius"; from: 20; to: surfaceViewRoot.maxScreenSpan * 0.65; duration: 480; easing.type: Easing.OutCubic }
        SequentialAnimation {
            PauseAnimation { duration: 40 }
            NumberAnimation { target: surfaceViewRoot; property: "portalInnerOpacity"; from: 0.65; to: 0.0; duration: 420; easing.type: Easing.OutQuad }
        }
    }

    ParallelAnimation {
        id: unlockPortalAnim
        NumberAnimation { target: surfaceViewRoot; property: "bgZoom"; to: 1.14; duration: 500; easing.type: Easing.InOutCubic }
        NumberAnimation { target: surfaceViewRoot; property: "blurMultiplier"; to: 0.0; duration: 400; easing.type: Easing.OutQuad }
        NumberAnimation { target: surfaceViewRoot; property: "portalPullProgress"; from: 0.0; to: 0.52; duration: 400; easing.type: Easing.InBack; easing.overshoot: 1.2 }
        NumberAnimation { target: surfaceViewRoot; property: "modulesScale"; to: 0.62; duration: 380; easing.type: Easing.InBack }
        NumberAnimation { target: surfaceViewRoot; property: "modulesOpacity"; to: 0.0; duration: 300; easing.type: Easing.InQuad }
        NumberAnimation { target: surfaceViewRoot; property: "authExtraScale"; to: 0.72; duration: 380; easing.type: Easing.InBack }
        NumberAnimation { target: surfaceViewRoot; property: "portalRingRadius"; from: surfaceViewRoot.maxScreenSpan * 0.75; to: 36; duration: 440; easing.type: Easing.InQuart }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "portalRingOpacity"; from: 0.0; to: 0.95; duration: 140; easing.type: Easing.OutQuad }
            NumberAnimation { target: surfaceViewRoot; property: "portalRingOpacity"; to: 0.0; duration: 320; easing.type: Easing.InCubic }
        }
        NumberAnimation { target: surfaceViewRoot; property: "portalInnerRadius"; from: 40; to: surfaceViewRoot.maxScreenSpan * 0.85; duration: 500; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: surfaceViewRoot; property: "portalInnerOpacity"; from: 0.85; to: 0.0; duration: 480; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 160 }
            NumberAnimation { target: surfaceViewRoot; property: "surfaceOpacity"; to: 0.0; duration: 350; easing.type: Easing.InOutCubic }
        }
    }

    function stopAllAnimations() {
        enterDefaultAnim.stop();
        unlockDefaultAnim.stop();
        enterStaggeredAnim.stop();
        unlockStaggeredAnim.stop();
        enterCurtainAnim.stop();
        unlockCurtainAnim.stop();
        enterDepthAnim.stop();
        unlockDepthAnim.stop();
        enterPortalAnim.stop();
        unlockPortalAnim.stop();
    }

    function startEntranceAnimation() {
        stopAllAnimations();
        surfaceViewRoot.authOffsetX = 0;
        surfaceViewRoot.authOffsetY = 0;
        surfaceViewRoot.authExtraScale = 1.0;
        surfaceViewRoot.curtainProgress = 0.0;
        surfaceViewRoot.curtainSplitOffset = 0.0;
        surfaceViewRoot.curtainSeamOpacity = 0.0;
        surfaceViewRoot.curtainSeamWidth = 0.0;
        surfaceViewRoot.depthFlashOpacity = 0.0;
        surfaceViewRoot.portalPullProgress = 0.0;
        surfaceViewRoot.portalRingOpacity = 0.0;
        surfaceViewRoot.portalInnerOpacity = 0.0;
        surfaceViewRoot.modulesBlur = 0.0;
        surfaceViewRoot.blurMultiplier = 1.0;

        if (!surfaceViewRoot.animEnabled) {
            surfaceViewRoot.surfaceOpacity = 1.0;
            surfaceViewRoot.bgZoom = 1.0;
            surfaceViewRoot.modulesOpacity = 1.0;
            surfaceViewRoot.modulesScale = 1.0;
            return;
        }

        const style = surfaceViewRoot.animStyle;
        if (style === "staggered") {
            surfaceViewRoot.modulesOpacity = 1.0;
            surfaceViewRoot.modulesScale = 1.0;
            surfaceViewRoot.staggeredEnterTriggered();
            enterStaggeredAnim.start();
        } else if (style === "curtain") {
            enterCurtainAnim.start();
        } else if (style === "depth") {
            enterDepthAnim.start();
        } else if (style === "portal") {
            enterPortalAnim.start();
        } else {
            enterDefaultAnim.start();
        }
    }

    function triggerShake() {
        authBox.triggerShake();
    }

    function triggerSuccess() {
        authBox.triggerSuccess();
        if (!surfaceViewRoot.animEnabled) return;

        stopAllAnimations();
        const style = surfaceViewRoot.animStyle;
        if (style === "staggered") {
            surfaceViewRoot.staggeredExitTriggered();
            unlockStaggeredAnim.start();
        } else if (style === "curtain") {
            unlockCurtainAnim.start();
        } else if (style === "depth") {
            unlockDepthAnim.start();
        } else if (style === "portal") {
            unlockPortalAnim.start();
        } else {
            unlockDefaultAnim.start();
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
        startEntranceAnimation();
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
            if (src === "custom" && LockscreenConfig.validatedCustomWallpaperPath !== "")
                return "file://" + LockscreenConfig.validatedCustomWallpaperPath;
            if (src === "effects")
                return "file://" + home + "/.cache/quickshell/wallpaper_effects/wallpaper_modified.png";
            if (src === "screenshot")
                return "file:///tmp/lockscreen_screenshot.png";
            const cur = (typeof WallpaperService !== "undefined")
                ? (WallpaperService.currentWallpaper || WallpaperService.wallpaperA || "")
                : "";
            if (cur !== "") return "file://" + cur;
            return "";
        }
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.max(1, surfaceViewRoot.width)
        sourceSize.height: Math.max(1, surfaceViewRoot.height)
        cache: false
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

    // Depth-of-Field / Lens Flash Overlay
    Rectangle {
        anchors.fill: parent
        color: surfaceViewRoot.theme.accentPrimary
        opacity: surfaceViewRoot.depthFlashOpacity
        visible: opacity > 0
    }

    // Subtle Accent Green Flash Overlay on Unlock Success
    Rectangle {
        anchors.fill: parent
        color: surfaceViewRoot.theme.accentGreen
        opacity: surfaceViewRoot.successGlowOpacity
        visible: opacity > 0
    }

    // Portal Radial Shockwave Rings (visible in "portal" animation style)
    Item {
        anchors.fill: parent
        visible: surfaceViewRoot.portalRingOpacity > 0 || surfaceViewRoot.portalInnerOpacity > 0
        z: 5

        Rectangle {
            x: surfaceViewRoot.portalOriginX - width / 2
            y: surfaceViewRoot.portalOriginY - height / 2
            width: surfaceViewRoot.portalRingRadius * 2
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 3
            border.color: surfaceViewRoot.theme.accentPrimary
            opacity: surfaceViewRoot.portalRingOpacity
            visible: opacity > 0
        }

        Rectangle {
            x: surfaceViewRoot.portalOriginX - width / 2
            y: surfaceViewRoot.portalOriginY - height / 2
            width: surfaceViewRoot.portalInnerRadius * 2
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: surfaceViewRoot.theme.accentGreen
            opacity: surfaceViewRoot.portalInnerOpacity
            visible: opacity > 0
        }
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

            property real staggerSlideProgress: (surfaceViewRoot.animEnabled && surfaceViewRoot.animStyle === "staggered") ? 1.0 : 0.0
            property real staggerOpacity: (surfaceViewRoot.animEnabled && surfaceViewRoot.animStyle === "staggered") ? 0.0 : 1.0
            property real staggerScale: (surfaceViewRoot.animEnabled && surfaceViewRoot.animStyle === "staggered") ? 0.86 : 1.0

            readonly property real edgeOffsetX: {
                if (_halign === "left") return -120;
                if (_halign === "right") return 120;
                return 0;
            }
            readonly property real edgeOffsetY: {
                if (_valign === "top") return -100;
                if (_valign === "bottom") return 100;
                return (_halign === "center") ? 55 : 0;
            }

            SequentialAnimation {
                id: modStaggerEnterAnim
                PauseAnimation { duration: Math.min(240, modItem.index * 50) }
                ParallelAnimation {
                    NumberAnimation { target: modItem; property: "staggerSlideProgress"; from: 1.0; to: 0.0; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
                    NumberAnimation { target: modItem; property: "staggerOpacity"; from: 0.0; to: 1.0; duration: 280; easing.type: Easing.OutCubic }
                    NumberAnimation { target: modItem; property: "staggerScale"; from: 0.86; to: 1.0; duration: 380; easing.type: Easing.OutBack }
                }
            }

            SequentialAnimation {
                id: modStaggerExitAnim
                PauseAnimation { duration: Math.min(180, modItem.index * 35) }
                ParallelAnimation {
                    NumberAnimation { target: modItem; property: "staggerSlideProgress"; from: 0.0; to: 1.15; duration: 360; easing.type: Easing.InBack; easing.overshoot: 1.25 }
                    NumberAnimation { target: modItem; property: "staggerOpacity"; from: 1.0; to: 0.0; duration: 260; easing.type: Easing.InQuad }
                    NumberAnimation { target: modItem; property: "staggerScale"; from: 1.0; to: 0.88; duration: 340; easing.type: Easing.InCubic }
                }
            }

            Connections {
                target: surfaceViewRoot
                function onStaggeredEnterTriggered() {
                    modStaggerExitAnim.stop();
                    modItem.staggerSlideProgress = 1.0;
                    modItem.staggerOpacity = 0.0;
                    modItem.staggerScale = 0.86;
                    modStaggerEnterAnim.start();
                }
                function onStaggeredExitTriggered() {
                    modStaggerEnterAnim.stop();
                    modStaggerExitAnim.start();
                }
            }

            opacity: surfaceViewRoot.animStyle === "staggered"
                ? modItem.staggerOpacity
                : surfaceViewRoot.modulesOpacity
            scale: surfaceViewRoot.animStyle === "staggered"
                ? modItem.staggerScale
                : surfaceViewRoot.modulesScale

            width: host.implicitWidth
            height: host.implicitHeight

            readonly property int _trigger: LockscreenConfig.refreshTrigger
            readonly property string _halign: mData ? (mData.halign || "center") : "center"
            readonly property string _valign: mData ? (mData.valign || "center") : "center"
            readonly property real _posX: mData ? (mData.position_x !== undefined ? mData.position_x : 0) : 0
            readonly property real _posY: mData ? (mData.position_y !== undefined ? mData.position_y : 0) : 0

            readonly property real baseTargetX: (_trigger >= 0 && mData) ? Math.round(surfaceViewRoot.calculateX(_halign, _posX, width)) : 0
            readonly property real baseTargetY: (_trigger >= 0 && mData) ? Math.round(surfaceViewRoot.calculateY(_valign, _posY, height)) : 0

            // Curtain split offset (top half lifts up, bottom half drops down)
            readonly property real curtainOffsetY: {
                if (surfaceViewRoot.curtainSplitOffset === 0) return 0;
                const isTopHalf = (baseTargetY + height / 2) <= (surfaceViewRoot.height / 2);
                return (isTopHalf ? -140 : 140) * surfaceViewRoot.curtainSplitOffset;
            }

            // Portal radial pull offset toward authBox center
            readonly property real portalOffsetX: {
                if (surfaceViewRoot.portalPullProgress === 0) return 0;
                return (surfaceViewRoot.portalOriginX - (baseTargetX + width / 2)) * surfaceViewRoot.portalPullProgress;
            }
            readonly property real portalOffsetY: {
                if (surfaceViewRoot.portalPullProgress === 0) return 0;
                return (surfaceViewRoot.portalOriginY - (baseTargetY + height / 2)) * surfaceViewRoot.portalPullProgress;
            }

            x: Math.round(baseTargetX + (modItem.edgeOffsetX * modItem.staggerSlideProgress) + portalOffsetX)
            y: Math.round(baseTargetY + (modItem.edgeOffsetY * modItem.staggerSlideProgress) + curtainOffsetY + portalOffsetY)

            layer.enabled: surfaceViewRoot.modulesBlur > 0.01
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 32
                blur: surfaceViewRoot.modulesBlur
            }

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

        readonly property real baseAuthX: (_trigger >= 0) ? Math.round(surfaceViewRoot.calculateX(targetHAlign, targetPosX, width)) : 0
        readonly property real baseAuthY: (_trigger >= 0) ? Math.round(surfaceViewRoot.calculateY(targetVAlign, targetPosY, height)) : 0

        x: Math.round(baseAuthX + surfaceViewRoot.authOffsetX)
        y: Math.round(baseAuthY + surfaceViewRoot.authOffsetY)
        scale: boxSuccessScale * surfaceViewRoot.authExtraScale

        layer.enabled: surfaceViewRoot.modulesBlur > 0.01
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 32
            blur: surfaceViewRoot.modulesBlur
        }

        onSubmit: pwd => surfaceViewRoot.submitPassword(pwd)
    }

    // Cinema Curtain Split Panels & Laser Seam Overlay
    Item {
        anchors.fill: parent
        visible: surfaceViewRoot.curtainProgress > 0.001 || surfaceViewRoot.curtainSeamOpacity > 0.001
        z: 50

        // Top Shutter Curtain
        Rectangle {
            width: parent.width
            height: (parent.height / 2) * surfaceViewRoot.curtainProgress
            anchors.top: parent.top
            color: surfaceViewRoot.theme.bgBase
            opacity: 0.94
        }

        // Bottom Shutter Curtain
        Rectangle {
            width: parent.width
            height: (parent.height / 2) * surfaceViewRoot.curtainProgress
            anchors.bottom: parent.bottom
            color: surfaceViewRoot.theme.bgBase
            opacity: 0.94
        }

        // Center Horizontal Laser Seam
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * surfaceViewRoot.curtainSeamWidth
            height: 2
            radius: 1
            color: surfaceViewRoot.theme.accentPrimary
            opacity: surfaceViewRoot.curtainSeamOpacity
        }
    }
}
