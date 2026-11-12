pragma Singleton
import QtQuick
import "../../../ThemeSwitcher"

// Shared look-and-feel for all Settings widgets in this folder.
QtObject {
    readonly property var theme: Theme
    // Emitted by Common widgets with announce:true; pages show it in their own toast.
    signal toast(string msg)

    readonly property string font: (theme && theme.fontFamily) ? theme.fontFamily : "Lato Nerd Font"
    readonly property string monoFont: (theme && theme.monoFont) ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property real fontScale: (theme && theme.fontScale !== undefined) ? theme.fontScale : 1.0
    readonly property real letterSpacing: (theme && theme.letterSpacing !== undefined) ? theme.letterSpacing : 0.0
    readonly property bool boldHeadings: (theme && theme.boldHeadings !== undefined) ? theme.boldHeadings : true
    readonly property int fontWeightEnum: (theme && theme.fontWeightEnum !== undefined) ? theme.fontWeightEnum : Font.Normal
    readonly property int fontHintingEnum: (theme && theme.fontHintingEnum !== undefined) ? theme.fontHintingEnum : Font.PreferDefaultHinting
    readonly property bool fontAntialiasing: (theme && theme.fontAntialiasing !== undefined) ? theme.fontAntialiasing : true
    readonly property int fontRenderTypeEnum: (theme && theme.fontRenderTypeEnum !== undefined) ? theme.fontRenderTypeEnum : Text.QtRendering

    function px(baseSize) {
        return Math.max(8, Math.round((Number(baseSize) || 12) * fontScale));
    }

    function withAlpha(col, alpha) {
        if (!col) return Qt.rgba(0, 0, 0, alpha);
        const c = Qt.color(col);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }
}
