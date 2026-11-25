pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string cacheFile: "/tmp/quickshell_clipboard.json"
    readonly property string serviceScript: Qt.resolvedUrl("scripts/clip_service.py").toString().replace(/^file:\/\//, "")

    property var items: []
    property int maxItems: ClipboardConfig.maxItems
    property bool loading: false
    property string activeCategory: "all"
    property string searchText: ""
    property string toastMessage: ""

    // Single-pass category counts
    readonly property int totalCount: items.length
    readonly property var _categoryCounts: {
        const counts = { text: 0, image: 0, link: 0, code: 0, color: 0 };
        for (let i = 0; i < items.length; i++) {
            const cat = items[i] ? items[i].category : "";
            if (counts[cat] !== undefined) counts[cat]++;
        }
        return counts;
    }
    readonly property int textCount: _categoryCounts.text
    readonly property int imageCount: _categoryCounts.image
    readonly property int linkCount: _categoryCounts.link
    readonly property int codeCount: _categoryCounts.code
    readonly property int colorCount: _categoryCounts.color

    Timer {
        id: toastResetTimer
        interval: 2200
        repeat: false
        onTriggered: root.toastMessage = ""
    }
    onToastMessageChanged: {
        if (root.toastMessage !== "") toastResetTimer.restart();
    }

    readonly property var filteredItems: {
        const q = searchText.toLowerCase().trim();
        const cat = activeCategory;
        let res = [];
        for (let i = 0; i < items.length; i++) {
            const it = items[i];
            if (!it) continue;
            // Category filter
            if (cat !== "all" && it.category !== cat) continue;
            // Text search filter
            if (q !== "") {
                const p = (it.preview || "").toLowerCase();
                const m = (it.imgMeta || "").toLowerCase();
                if (!p.includes(q) && !m.includes(q)) continue;
            }
            res.push(it);
        }
        return res;
    }

    signal itemCopied(string preview)
    signal itemDeleted(string id)
    signal wiped()

    function refresh() {
        if (loading) return;
        loading = true;
        listProcess.command = ["python3", root.serviceScript, "list", String(root.maxItems), root.cacheFile];
        listProcess.running = true;
    }

    function releaseMemory() {
        cacheWatcher.path = "";
        root.items = [];
    }

    function copyItem(id, preview) {
        copyProcess.command = ["python3", root.serviceScript, "copy", String(id)];
        copyProcess.running = true;
        root.toastMessage = "Copied to clipboard";
        root.itemCopied(preview || "");
    }

    function deleteItem(id) {
        deleteProcess.command = ["python3", root.serviceScript, "delete", String(id)];
        deleteProcess.running = true;
        // Immediate local remove for snappy responsiveness
        let copy = [];
        for (let i = 0; i < root.items.length; i++) {
            if (root.items[i].id !== String(id)) {
                copy.push(root.items[i]);
            }
        }
        root.items = copy;
        root.toastMessage = "Item deleted";
        root.itemDeleted(String(id));
    }

    function wipeAll() {
        wipeProcess.command = ["python3", root.serviceScript, "wipe"];
        wipeProcess.running = true;
        root.items = [];
        root.toastMessage = "Clipboard wiped";
        root.wiped();
        ClipboardConfig.historyWiped();
    }

    Process {
        id: listProcess
        running: false
        onExited: {
            root.loading = false;
            if (cacheWatcher.path !== root.cacheFile) {
                cacheWatcher.path = root.cacheFile;
            } else {
                cacheWatcher.reload();
            }
        }
    }

    Process {
        id: copyProcess
        running: false
    }

    Process {
        id: deleteProcess
        running: false
    }

    Process {
        id: wipeProcess
        running: false
    }

    FileView {
        id: cacheWatcher
        path: ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            const raw = cacheWatcher.text();
            if (!raw) return;
            try {
                const parsed = JSON.parse(raw);
                if (Array.isArray(parsed)) {
                    root.items = parsed;
                }
            } catch (e) {
                console.error("Failed to parse clipboard cache:", e);
            }
        }
    }
}
