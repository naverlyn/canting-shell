import QtQuick
import Quickshell
import "../ThemeSwitcher"
import "../Settings/Components"

ShellRoot {
    FloatingWindow {
        width: 900; height: 700
        visible: true
        BarSettings {
            anchors.fill: parent
            theme: Theme
            Component.onCompleted: Qt.callLater(function() { currentSubTab = 2; Qt.callLater(function() { currentSubTab = 1; Qt.callLater(function(){ console.log("TESTDONE"); Qt.quit(); }) }) })
        }
    }
}
