import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  id: csPill

  property bool isPinned: false
  property string outputText: ""
  property string outputTooltip: ""
  property string outputIcon: ""

  readonly property string resolvedIcon: outputIcon !== "" ? outputIcon : BarConfig.customScriptIcon
  readonly property string truncatedText: {
    const maxLen = Math.max(4, BarConfig.customScriptMaxLength || 28);
    if (!outputText) return "";
    return outputText.length > maxLen ? (outputText.substring(0, maxLen - 1) + "…") : outputText;
  }
  readonly property bool shouldHide: Boolean(BarConfig.customScriptHideWhenEmpty) && outputText === ""

  visible: !shouldHide
  implicitHeight: shouldHide ? 0 : (hostContainer.isVert ? (csVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24))
  implicitWidth: shouldHide ? 0 : (hostContainer.isVert ? hostContainer.vertPillWidth : (csContent.implicitWidth + 14))
  height: implicitHeight
  width: implicitWidth
  scale: csMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("customScript", csHover.hovered || csMouse.containsMouse || csPill.isPinned)
  border.color: hostContainer.wBorder("customScript")
  border.width: hostContainer.hasCustomColor("customScript") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Custom Script: " + outputText

  HoverHandler { id: csHover }

  function runScript() {
    const cmd = (BarConfig.customScriptCommand || "").trim();
    if (!cmd) {
      csPill.outputText = "";
      csPill.outputTooltip = "No command configured";
      return;
    }
    if (execProc.running) return;
    execProc.command = ["sh", "-c", cmd];
    execProc.running = true;
  }

  Connections {
    target: BarConfig
    function onCustomScriptRevisionChanged() {
      csPill.runScript();
    }
  }

  Process {
    id: execProc
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const raw = text.trim();
        if (!raw) {
          csPill.outputText = "";
          csPill.outputTooltip = "";
          csPill.outputIcon = "";
          return;
        }
        if (raw.charAt(0) === "{") {
          try {
            const obj = JSON.parse(raw.split("\n")[0]);
            csPill.outputText = String(obj.text !== undefined ? obj.text : "");
            csPill.outputTooltip = String(obj.tooltip !== undefined ? obj.tooltip : csPill.outputText);
            csPill.outputIcon = String(obj.icon !== undefined ? obj.icon : (obj.alt !== undefined ? obj.alt : ""));
            return;
          } catch (e) {}
        }
        const lines = raw.split("\n");
        csPill.outputText = lines[0].trim();
        csPill.outputTooltip = lines.length > 1 ? lines.slice(1).join("\n").trim() : lines[0].trim();
        csPill.outputIcon = "";
      }
    }
  }

  Process {
    id: clickProc
    running: false
    onExited: csPill.runScript()
  }

  Timer {
    interval: Math.max(1, BarConfig.customScriptInterval || 10) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: csPill.runScript()
  }

  Item {
    id: csProvider
    visible: false
    width: 0
    height: 0
    property Item target: csPill
    property var barItem: hostContainer
    property var hostRoot: csPill.hostRoot
    property bool hovered: Boolean(BarConfig.customScriptShowPopup) && (csHover.hovered || csMouse.containsMouse) && csPill.outputTooltip !== ""
    property bool pinned: Boolean(BarConfig.customScriptShowPopup) && csPill.isPinned
    property bool effectiveHovered: false
    readonly property bool isSharedCardHovered: Boolean(barItem && barItem.activeInfoProvider === csProvider && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered)
    readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered
    property var theme: hostRoot.theme
    property string font: hostRoot.font
    property string title: "Custom Script"
    property string icon: csPill.resolvedIcon
    property color accent: hostContainer.wAccent("customScript", hostRoot.theme.accentCyan)
    property bool hideHeader: true
    property int preferredWidth: 264
    property int preferredHeight: 0
    property var rows: []

    Timer {
      id: csCloseTimer
      interval: 150
      onTriggered: {
        if (!csProvider.hovered && !csProvider.isSharedCardHovered) {
          csProvider.effectiveHovered = false;
          if (hostContainer.activeInfoProvider === csProvider && !csProvider.pinned)
            hostContainer.activeInfoProvider = null;
        }
      }
    }
    onHoveredChanged: {
      if (hovered) {
        csCloseTimer.stop();
        effectiveHovered = true;
        hostContainer.activeInfoProvider = csProvider;
      } else if (!isSharedCardHovered) {
        csCloseTimer.restart();
      }
    }
    onIsSharedCardHoveredChanged: {
      if (isSharedCardHovered) { csCloseTimer.stop(); effectiveHovered = true; }
      else if (!hovered) csCloseTimer.restart();
    }
    onPinnedChanged: {
      if (pinned) {
        const o = hostContainer.activeInfoProvider;
        if (o && o !== csProvider && o.target && o.target.isPinned !== undefined) o.target.isPinned = false;
        hostContainer.activeInfoProvider = csProvider;
      } else if (!hovered && !isSharedCardHovered && hostContainer.activeInfoProvider === csProvider) {
        hostContainer.activeInfoProvider = null;
      }
    }
    Component.onDestruction: {
      if (hostContainer.activeInfoProvider === csProvider) hostContainer.activeInfoProvider = null;
    }

    property Component contentComponent: Component {
      ColumnLayout {
        spacing: 8
        readonly property var th: csProvider.theme

        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: "Custom Script"
            font.family: csProvider.font
            font.pixelSize: 13
            font.bold: true
            color: th.textPrimary
          }

          Item { Layout.fillWidth: true }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: csPopupTooltipText.implicitHeight + 18
          radius: 8
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.05)
          border.color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
          border.width: 1

          Text {
            id: csPopupTooltipText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 9
            text: csPill.outputTooltip || csPill.outputText || "No output"
            font.family: csProvider.font
            font.pixelSize: 11
            color: th.textPrimary
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  Text {
    id: csMeasureTooltipText
    visible: false
    width: 220
    text: csPill.outputTooltip || csPill.outputText || "No output"
    font.family: hostRoot.font
    font.pixelSize: 11
    wrapMode: Text.WordWrap
  }

  PillIndicator {
    hostRoot: csPill.hostRoot
    hostContainer: csPill.hostContainer
    active: csMouse.pressed || csPill.isPinned
    hovered: csHover.hovered || csMouse.containsMouse
    accentColor: hostContainer.wAccent("customScript", hostRoot.theme.accentCyan)
  }

  Row {
    id: csContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      visible: csPill.resolvedIcon !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: csPill.resolvedIcon
      color: hostContainer.wAccent("customScript", hostRoot.theme.accentCyan)
      font.pixelSize: 14
      font.family: hostRoot.font
    }

    Text {
      visible: csPill.truncatedText !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: csPill.truncatedText
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: csVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      visible: csPill.resolvedIcon !== ""
      anchors.horizontalCenter: parent.horizontalCenter
      text: csPill.resolvedIcon
      color: hostContainer.wAccent("customScript", hostRoot.theme.accentCyan)
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      visible: csPill.outputText !== ""
      anchors.horizontalCenter: parent.horizontalCenter
      text: csPill.outputText.substring(0, 4)
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }

  MouseArea {
    id: csMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        const rCmd = (BarConfig.customScriptOnRightClick || "").trim();
        if (rCmd) {
          clickProc.command = ["sh", "-c", rCmd];
          clickProc.running = true;
        } else {
          csPill.runScript();
        }
      } else {
        const lCmd = (BarConfig.customScriptOnClick || "").trim();
        if (lCmd) {
          clickProc.command = ["sh", "-c", lCmd];
          clickProc.running = true;
        } else if (BarConfig.customScriptShowPopup) {
          csPill.isPinned = !csPill.isPinned;
        }
      }
    }
  }
}
