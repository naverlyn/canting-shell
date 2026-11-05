.pragma library

var APPS = [
    {
        id: "whatsapp",
        name: "WhatsApp",
        color: "#25D366",
        icon: "󰖣",
        appIcon: "whatsapp",
        domains: ["web.whatsapp.com", "whatsapp.com"],
        keywords: ["whatsapp", "zapzap"],
        titleMatch: ".*WhatsApp.*",
        classMatch: ".*(brave|whatsapp|zapzap|chrome).*",
        fallbackUrl: "https://web.whatsapp.com"
    },
    {
        id: "discord",
        name: "Discord",
        color: "#5865F2",
        icon: "󰙯",
        appIcon: "discord",
        domains: ["discord.com", "discordapp.com"],
        keywords: ["discord", "vesktop", "webcord", "armcord"],
        titleMatch: ".*Discord.*",
        classMatch: ".*(discord|vesktop|webcord|armcord|brave|chrome).*",
        fallbackUrl: "https://discord.com/app"
    },
    {
        id: "telegram",
        name: "Telegram",
        color: "#229ED9",
        icon: "󰈎",
        appIcon: "telegram",
        domains: ["web.telegram.org", "telegram.org"],
        keywords: ["telegram", "telegramdesktop", "org.telegram.desktop"],
        titleMatch: ".*Telegram.*",
        classMatch: ".*(telegramdesktop|org.telegram.desktop|telegram|brave|chrome).*",
        fallbackUrl: "https://web.telegram.org"
    },
    {
        id: "slack",
        name: "Slack",
        color: "#E01E5A",
        icon: "󰒱",
        appIcon: "slack",
        domains: ["app.slack.com", "slack.com"],
        keywords: ["slack"],
        titleMatch: ".*Slack.*",
        classMatch: ".*(slack|brave|chrome).*",
        fallbackUrl: "https://app.slack.com"
    },
    {
        id: "messenger",
        name: "Messenger",
        color: "#00B2FF",
        icon: "󰈿",
        appIcon: "messenger",
        domains: ["messenger.com"],
        keywords: ["messenger", "caprine", "facebook messenger"],
        titleMatch: ".*Messenger.*",
        classMatch: ".*(messenger|caprine|brave|chrome).*",
        fallbackUrl: "https://www.messenger.com"
    },
    {
        id: "instagram",
        name: "Instagram",
        color: "#E1306C",
        icon: "󰋄",
        appIcon: "instagram",
        domains: ["instagram.com"],
        keywords: ["instagram"],
        titleMatch: ".*Instagram.*",
        classMatch: ".*(instagram|brave|chrome).*",
        fallbackUrl: "https://www.instagram.com"
    },
    {
        id: "signal",
        name: "Signal",
        color: "#3A76F0",
        icon: "󰭹",
        appIcon: "signal-desktop",
        domains: [],
        keywords: ["signal", "signal-desktop", "org.thoughtcrime.securesms"],
        titleMatch: ".*Signal.*",
        classMatch: ".*(signal).*",
        fallbackUrl: ""
    },
    {
        id: "teams",
        name: "Microsoft Teams",
        color: "#6264A7",
        icon: "󰊻",
        appIcon: "teams",
        domains: ["teams.microsoft.com", "teams.live.com"],
        keywords: ["teams", "teams-for-linux"],
        titleMatch: ".*Teams.*",
        classMatch: ".*(teams|teams-for-linux|brave|chrome).*",
        fallbackUrl: "https://teams.microsoft.com"
    },
    {
        id: "element",
        name: "Element",
        color: "#0DBD8B",
        icon: "󰘎",
        appIcon: "element",
        domains: ["app.element.io"],
        keywords: ["element", "cinny", "matrix"],
        titleMatch: ".*Element.*",
        classMatch: ".*(element|cinny|fluffychat|brave|chrome).*",
        fallbackUrl: "https://app.element.io"
    }
];

function detectApp(appName, appIcon, summary, body) {
    var aName = (appName || "").toLowerCase();
    var aIcon = (appIcon || "").toLowerCase();
    var aSum  = (summary || "").toLowerCase();
    var aBody = (body || "").toLowerCase();

    // 1. Check domains in body (web notifications usually have domain in body)
    for (var i = 0; i < APPS.length; i++) {
        var app = APPS[i];
        for (var d = 0; d < app.domains.length; d++) {
            if (aBody.indexOf(app.domains[d]) !== -1) {
                return app;
            }
        }
    }

    // 2. Check app name and icon
    for (var i = 0; i < APPS.length; i++) {
        var app = APPS[i];
        for (var k = 0; k < app.keywords.length; k++) {
            var kw = app.keywords[k];
            if (aName.indexOf(kw) !== -1 || aIcon.indexOf(kw) !== -1) {
                return app;
            }
        }
    }

    // 3. Check summary (e.g. app name in summary)
    for (var i = 0; i < APPS.length; i++) {
        var app = APPS[i];
        for (var k = 0; k < app.keywords.length; k++) {
            var kw = app.keywords[k];
            if (aSum.indexOf(kw) !== -1) {
                return app;
            }
        }
    }

    return null;
}

function cleanBody(body, app) {
    if (!body) return "";
    var clean = body;
    if (app && app.domains) {
        for (var i = 0; i < app.domains.length; i++) {
            var d = app.domains[i].replace(/\./g, "\\.");
            var re = new RegExp("^(?:https?:\\/\\/)?" + d + "(?:\\/[^\\s\\n]*)?\\s*\\n*", "i");
            clean = clean.replace(re, "");
        }
    }
    clean = clean.trim();
    return clean.length > 0 ? clean : body;
}

function formatAppName(originalName, app) {
    if (!app) return originalName || "Notification";
    var orig = (originalName || "").toLowerCase();
    if (!originalName || orig === "notification" || orig === "brave" || orig === "chromium" || orig === "chrome" || orig === "firefox") {
        return app.name + " Web";
    }
    return originalName;
}

function getFocusCommand(app) {
    if (!app) return "";
    var titleArg = '"title:' + app.titleMatch + '"';
    var classArg = '"class:' + app.classMatch + '"';
    
    // Fallback: If not found, only launch browser URL if browser is completely closed.
    var launchFallback = "";
    if (app.fallbackUrl) {
        launchFallback = 'if ! pgrep -i brave >/dev/null 2>&1; then brave "' + app.fallbackUrl + '" >/dev/null 2>&1 & fi; ';
    }
    
    return 'if ! hyprctl dispatch focuswindow ' + titleArg + ' 2>&1 | grep -q "ok"; then ' +
           'if ! hyprctl dispatch focuswindow ' + classArg + ' 2>&1 | grep -q "ok"; then ' +
           launchFallback +
           'fi; fi';
}
