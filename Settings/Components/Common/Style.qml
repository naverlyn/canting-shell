pragma Singleton
import QtQuick
import "../../../ThemeSwitcher"

// Shared look-and-feel for all Settings widgets in this folder.
QtObject {
    readonly property var theme: Theme
    // Emitted by Common widgets with announce:true; pages show it in their own toast.
    signal toast(string msg)

    readonly property string font: "Lato Nerd Font"

    function withAlpha(col, alpha) {
        if (!col) return Qt.rgba(0, 0, 0, alpha);
        const c = Qt.color(col);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }
}
