.pragma library

var LAYOUT_PRESETS = {
    standard: {
        headerBlocks: ["icon", "appName", "closeBtn"],
        contentBlocks: ["title", "body", "image"],
        footerBlocks: ["buttons", "progressBar"],
        iconMode: "auto",
        iconSize: 24,
        imagePosition: "right",
        imageSize: 44,
        buttonStyle: "pill",
        showAccentStrip: true,
        accentStripPosition: "left"
    },
    avatar: {
        headerBlocks: ["appName", "timestamp", "closeBtn"],
        contentBlocks: ["icon", "title", "body", "image"],
        footerBlocks: ["buttons", "progressBar"],
        iconMode: "avatar",
        iconSize: 36,
        imagePosition: "right",
        imageSize: 44,
        buttonStyle: "fill",
        showAccentStrip: true,
        accentStripPosition: "left"
    },
    banner: {
        headerBlocks: ["icon", "appName", "timestamp", "closeBtn"],
        contentBlocks: ["title", "body", "image"],
        footerBlocks: ["buttons", "progressBar"],
        iconMode: "inline",
        iconSize: 24,
        imagePosition: "banner",
        imageSize: 72,
        buttonStyle: "fill",
        showAccentStrip: true,
        accentStripPosition: "top"
    },
    compact: {
        headerBlocks: ["icon", "title", "closeBtn"],
        contentBlocks: ["body"],
        footerBlocks: ["buttons"],
        iconMode: "inline",
        iconSize: 20,
        imageSize: 44,
        buttonStyle: "ghost",
        showAccentStrip: true,
        accentStripPosition: "left"
    },
    detailed: {
        headerBlocks: ["icon", "appName", "timestamp", "closeBtn"],
        contentBlocks: ["title", "body", "image"],
        footerBlocks: ["buttons", "progressBar"],
        iconMode: "auto",
        iconSize: 24,
        imagePosition: "right",
        imageSize: 44,
        buttonStyle: "pill",
        showAccentStrip: true,
        accentStripPosition: "left"
    }
};

function getComposerPreset(presetId, urgencyEnum) {
    var map = {
        screenshot: {
            appName: "notify-send",
            icon: "󰂚",
            title: "Screenshot:",
            body: "Captured by Swappy",
            showImage: true,
            urgency: urgencyEnum.Normal,
            buttons: [
                { label: "Open", cmd: "" },
                { label: "Delete", cmd: "" }
            ]
        },
        message: {
            appName: "WhatsApp Web",
            icon: "󰖣",
            title: "Alex Rivera",
            body: "Hey! Are we still on for the design review at 10:00?",
            showImage: false,
            urgency: urgencyEnum.Normal,
            buttons: [
                { label: "Reply", cmd: "" },
                { label: "Mark Read", cmd: "" }
            ]
        },
        media: {
            appName: "Spotify",
            icon: "󰓇",
            title: "Midnight City",
            body: "M83 — Hurry Up, We're Dreaming",
            showImage: true,
            urgency: urgencyEnum.Low,
            buttons: [
                { label: "Previous", cmd: "" },
                { label: "Pause", cmd: "" },
                { label: "Next", cmd: "" }
            ]
        },
        critical: {
            appName: "System Monitor",
            icon: "󰀦",
            title: "Critical Battery Alert",
            body: "Battery level is at 7%. Connect power adapter immediately.",
            showImage: false,
            urgency: urgencyEnum.Critical,
            buttons: [
                { label: "Power Saver", cmd: "" },
                { label: "Dismiss", cmd: "" }
            ]
        }
    };
    return map[presetId] || null;
}
