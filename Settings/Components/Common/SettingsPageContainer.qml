import QtQuick

Item {
    id: pageContainer
    required property var hostApp
    required property var hostWindow
    required property int pageIndex
    required property Component pageComponent
    property alias item: pageLoader.item

    anchors.fill: parent
    anchors.margins: 24
    anchors.topMargin: 36
    visible: opacity > 0
    opacity: hostApp.currentTab === pageIndex ? 1 : 0
    scale: hostApp.currentTab === pageIndex ? 1 : 0.98
    y: hostApp.currentTab === pageIndex ? 0 : 8

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Loader {
        id: pageLoader
        anchors.fill: parent
        active: hostWindow.visible && (hostApp.currentTab === pageContainer.pageIndex || pageContainer.opacity > 0)
        sourceComponent: pageContainer.pageComponent
    }
}
