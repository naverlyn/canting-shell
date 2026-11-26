import QtQuick

// Reusable directional slide + fade module slot for DynamicIslandHubView (single tab & split right pane).
Item {
  id: slot

  required property var hubRoot
  required property string targetModuleId
  required property var moduleOrder
  property bool slotActive: true
  property int slideDistance: 18

  property string displayedModuleId: targetModuleId

  implicitHeight: modLoader.item ? modLoader.item.implicitHeight : 100
  clip: true

  onTargetModuleIdChanged: {
    if (!slot.visible || !slot.slotActive || displayedModuleId === targetModuleId) {
      switchAnim.stop();
      displayedModuleId = targetModuleId;
      modWrap.opacity = 1.0;
      modShift.x = 0;
      return;
    }
    const order = slot.moduleOrder || [];
    const oldIdx = order.indexOf(displayedModuleId);
    const newIdx = order.indexOf(targetModuleId);
    const dir = (oldIdx !== -1 && newIdx !== -1 && newIdx < oldIdx) ? -1 : 1;
    if (switchAnim.running) switchAnim.complete();
    switchAnim.direction = dir;
    switchAnim.nextModule = targetModuleId;
    switchAnim.restart();
  }

  SequentialAnimation {
    id: switchAnim
    property int direction: 1
    property string nextModule: "mpris"

    ParallelAnimation {
      NumberAnimation { target: modWrap; property: "opacity"; to: 0.0; duration: 85; easing.type: Easing.InQuad }
      NumberAnimation { target: modShift; property: "x"; to: switchAnim.direction * -slot.slideDistance; duration: 85; easing.type: Easing.InQuad }
    }
    ScriptAction {
      script: {
        slot.displayedModuleId = switchAnim.nextModule;
        modShift.x = switchAnim.direction * slot.slideDistance;
      }
    }
    ParallelAnimation {
      NumberAnimation { target: modWrap; property: "opacity"; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
      NumberAnimation { target: modShift; property: "x"; to: 0; duration: 160; easing.type: Easing.OutCubic }
    }
  }

  Item {
    id: modWrap
    anchors.left: parent.left
    anchors.right: parent.right
    height: slot.implicitHeight
    transform: Translate { id: modShift; x: 0 }

    Loader {
      id: modLoader
      active: slot.slotActive && slot.visible
      anchors.left: parent.left
      anchors.right: parent.right
      height: item ? item.implicitHeight : 100
      sourceComponent: slot.hubRoot.componentForModule(slot.displayedModuleId)
      onLoaded: {
        if (item) item.width = Qt.binding(() => modLoader.width);
      }
    }
  }
}
