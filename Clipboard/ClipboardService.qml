pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string cacheFile: "/tmp/quickshell_clipboard.json"
    readonly property string serviceScript: Qt.resolvedUrl("scripts/clip_service.py").toString().replace(/^file:\/\//, "")

    property var items: []
    property int maxItems: 100
    property bool loading: false
    property string activeCategory: "all"
    property string searchText: ""
    property string toastMessage: ""

    // Category counts
    readonly property int totalCount: items.length
    readonly property int textCount: {
        let c = 0;
        for (let i = 0; i < items.length; i++) if (items[i].category === "text") c++;
        return c;
    }
    readonly property int imageCount: {
        let c = 0;
        for (let i = 0; i < items.length; i++) if (items[i].category === "image") c++;
        return c;
    }
    readonly property int linkCount: {
        let c = 0;
        for (let i = 0; i < items.length; i++) if (items[i].category === "link") c++;
        return c;
    }
    readonly property int codeCount: {
        let c = 0;
        for (let i = 0; i < items.length; i++) if (items[i].category === "code") c++;
        return c;
    }
    readonly property int colorCount: {
        let c = 0;
        for (let i = 0; i < items.length; i++) if (items[i].category === "color") c++;
        return c;
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
