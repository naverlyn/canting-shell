import QtQuick
import Quickshell.Widgets

// Shared 3-tier notification app icon / file icon / fallback theme icon / Nerd Font glyph badge.
Item {
  id: badge

  property string themeSrc: ""
  property string fileSrc: ""
  property string fallbackThemeSrc: ""
  property string glyph: ""
  property color glyphColor: "#7aa2f7"
  property string font: "Lato Nerd Font"

  property int iconSize: 28
  property int glyphSize: 15
  property int badgeRadius: 9
  property real glyphBgAlpha: 0.14
  property real glyphBorderAlpha: 0.30

  readonly property bool hasRealIcon: themeImg.status === Image.Ready || fileImg.status === Image.Ready || fallbackImg.status === Image.Ready
  readonly property bool hasGlyphFallback: !hasRealIcon && glyph !== ""
  readonly property bool hasAnyVisual: hasRealIcon || hasGlyphFallback

  IconImage {
    id: themeImg
    anchors.centerIn: parent
    implicitSize: badge.iconSize
    source: badge.themeSrc
    visible: badge.themeSrc !== "" && status === Image.Ready
  }

  Image {
    id: fileImg
    anchors.centerIn: parent
    width: badge.iconSize
    height: badge.iconSize
    source: badge.fileSrc
    sourceSize.width: badge.iconSize * 2
    sourceSize.height: badge.iconSize * 2
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    cache: false
    visible: badge.fileSrc !== "" && status === Image.Ready && themeImg.status !== Image.Ready
  }

  IconImage {
    id: fallbackImg
    anchors.centerIn: parent
    implicitSize: badge.iconSize
    source: (themeImg.status !== Image.Ready && fileImg.status !== Image.Ready && badge.fallbackThemeSrc) ? badge.fallbackThemeSrc : ""
    visible: source !== "" && status === Image.Ready && themeImg.status !== Image.Ready && fileImg.status !== Image.Ready
  }

  Rectangle {
    anchors.fill: parent
    radius: badge.badgeRadius
    visible: badge.hasGlyphFallback
    color: Qt.rgba(badge.glyphColor.r, badge.glyphColor.g, badge.glyphColor.b, badge.glyphBgAlpha)
    border.color: Qt.rgba(badge.glyphColor.r, badge.glyphColor.g, badge.glyphColor.b, badge.glyphBorderAlpha)
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: badge.glyph
      font.family: badge.font
      font.pixelSize: badge.glyphSize
      color: badge.glyphColor
    }
  }
}
