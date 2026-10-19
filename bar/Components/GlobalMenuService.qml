pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string userBindsPath: (Quickshell.env("HOME") || "") + "/.config/hypr/UserConfigs/UserKeybinds.conf"
  readonly property string defaultBindsPath: (Quickshell.env("HOME") || "") + "/.config/hypr/configs/Keybinds.conf"

  property var parsedBinds: ({})
  property int bindsUpdateCounter: 0

  function getShortcut(actionKey, fallback) {
    void root.bindsUpdateCounter;
    if (root.parsedBinds && root.parsedBinds[actionKey]) {
      return root.parsedBinds[actionKey];
    }
    return fallback || "";
  }

  // Curated Simple Global Menus mapped to user's Hyprland environment
  readonly property var menus: [
    {
      id: 100,
      label: "File",
      children: [
        { id: 101, label: "New Terminal", icon: "󰌌", shortcut: root.getShortcut("terminal", "Ctrl+Alt+T"), hypr: "exec kitty" },
        { id: 102, label: "App Launcher", icon: "󰀻", shortcut: root.getShortcut("launcher", "Super+D"), hypr: "exec qs ipc call launcher toggle" },
        { id: 103, is_separator: true },
        { id: 104, label: "Close Window", icon: "󰅖", shortcut: root.getShortcut("closewindow", "Super+Q"), hypr: "closewindow activewindow" },
        { id: 105, label: "Force Kill", icon: "󰅚", shortcut: root.getShortcut("killprocess", "Super+Shift+Q"), hypr: "killactive" }
      ]
    },
    {
      id: 200,
      label: "Edit",
      children: [
        { id: 201, label: "Copy", icon: "󰆏", shortcut: "Ctrl+C", hypr: "sendshortcut Ctrl,c,activewindow" },
        { id: 202, label: "Paste", icon: "󰆒", shortcut: "Ctrl+V", hypr: "sendshortcut Ctrl,v,activewindow" },
        { id: 203, label: "Cut", icon: "󰆐", shortcut: "Ctrl+X", hypr: "sendshortcut Ctrl,x,activewindow" },
        { id: 204, is_separator: true },
        { id: 205, label: "Select All", icon: "󰒅", shortcut: "Ctrl+A", hypr: "sendshortcut Ctrl,a,activewindow" },
        { id: 206, label: "Undo", icon: "󰕌", shortcut: "Ctrl+Z", hypr: "sendshortcut Ctrl,z,activewindow" }
      ]
    },
    {
      id: 300,
      label: "View",
      children: [
        { id: 301, label: "Toggle Fullscreen", icon: "󰊓", shortcut: root.getShortcut("fullscreen", "Super+Shift+F"), hypr: "fullscreen 0" },
        { id: 302, label: "Toggle Floating", icon: "󰉈", shortcut: root.getShortcut("togglefloating", "Super+Space"), hypr: "togglefloating activewindow" },
        { id: 303, label: "Pin Window (Sticky)", icon: "󰤱", shortcut: root.getShortcut("pin", "Super+P"), hypr: "pin activewindow" },
        { id: 304, is_separator: true },
        { id: 305, label: "Center Window", icon: "󰍋", shortcut: "", hypr: "centerwindow" },
        { id: 306, label: "Take Screenshot", icon: "󰹑", shortcut: root.getShortcut("screenshot", "Super+Shift+S"), hypr: "exec $HOME/.config/hypr/scripts/ScreenShot.sh --swappy" }
      ]
    },
    {
      id: 400,
      label: "Window",
      children: [
        { id: 401, label: "Move to Workspace 1", icon: "󰒮", shortcut: root.getShortcut("moveto_1", "Super+Shift+1"), hypr: "movetoworkspace 1" },
        { id: 402, label: "Move to Workspace 2", icon: "󰒮", shortcut: root.getShortcut("moveto_2", "Super+Shift+2"), hypr: "movetoworkspace 2" },
        { id: 403, label: "Move to Workspace 3", icon: "󰒮", shortcut: root.getShortcut("moveto_3", "Super+Shift+3"), hypr: "movetoworkspace 3" },
        { id: 404, label: "Move to Workspace 4", icon: "󰒮", shortcut: root.getShortcut("moveto_4", "Super+Shift+4"), hypr: "movetoworkspace 4" },
        { id: 405, label: "Move to Workspace 5", icon: "󰒮", shortcut: root.getShortcut("moveto_5", "Super+Shift+5"), hypr: "movetoworkspace 5" },
        { id: 406, is_separator: true },
        { id: 407, label: "Toggle Split Layout", icon: "󰕰", shortcut: root.getShortcut("togglesplit", "Super+Shift+I"), hypr: "togglesplit" },
        { id: 408, label: "Toggle Scratchpad", icon: "󱂬", shortcut: root.getShortcut("togglespecialworkspace", "Super+U"), hypr: "togglespecialworkspace" }
      ]
    },
    {
      id: 500,
      label: "Help",
      children: [
        { id: 501, label: "Active Window: " + (Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"), icon: "🗔", shortcut: "", enabled: false },
        { id: 502, is_separator: true },
        { id: 503, label: "Hyprland Reload", icon: "󰑓", shortcut: "Super+Shift+R", hypr: "exec hyprctl reload" }
      ]
    }
  ]

  property int activeTopMenuIndex: -1
  readonly property bool isMenuOpen: activeTopMenuIndex >= 0

  function closeMenu() {
    root.activeTopMenuIndex = -1;
  }

  function triggerAction(item) {
    if (!item) return;
    if (item.hypr && item.hypr !== "") {
      try {
        Hyprland.dispatch(item.hypr);
      } catch (e) {
        console.error("Hyprland.dispatch failed:", e);
      }
    }
    root.closeMenu();
  }

  FileView {
    id: userBindsFile
    path: root.userBindsPath
    watchChanges: true
    printErrors: false
    onFileChanged: {
      userBindsFile.reload();
      root.updateKeybinds();
    }
    onTextChanged: root.updateKeybinds()
  }

  FileView {
    id: defaultBindsFile
    path: root.defaultBindsPath
    watchChanges: true
    printErrors: false
    onFileChanged: {
      defaultBindsFile.reload();
      root.updateKeybinds();
    }
    onTextChanged: root.updateKeybinds()
  }

  function updateKeybinds() {
    let binds = {};

    const parseText = (text) => {
      if (!text) return;
      const lines = text.split("\n");
      for (let i = 0; i < lines.length; i++) {
        let line = lines[i].trim();
        if (!line || line.startsWith("#")) continue;
        const match = line.match(/^bind[a-z]*\s*=\s*(.+)$/);
        if (!match) continue;
        const parts = match[1].split(",").map(s => s.trim());
        if (parts.length >= 3) {
          let mods = parts[0]
            .replace(/\$mainMod/g, "Super")
            .replace(/SUPER/g, "Super")
            .replace(/CTRL/g, "Ctrl")
            .replace(/ALT/g, "Alt")
            .replace(/SHIFT/g, "Shift")
            .trim();
          mods = mods.split(/\s+/).filter(Boolean).join("+");
          let key = parts[1].trim();
          if (key.startsWith("code:")) {
            const codeNum = parseInt(key.substring(5));
            if (codeNum >= 10 && codeNum <= 18) key = String(codeNum - 9);
            else if (codeNum === 19) key = "0";
          } else if (key === "SPACE" || key === "space") {
            key = "Space";
          } else if (key === "Return" || key === "return") {
            key = "Enter";
          }

          const shortcut = mods !== "" ? (mods + "+" + key) : key;
          const tail = parts.slice(2).join(",");

          if (tail.indexOf("togglefloating") !== -1) {
            binds["togglefloating"] = shortcut;
          } else if (tail.indexOf("KillActiveProcess") !== -1) {
            binds["killprocess"] = shortcut;
          } else if (tail.indexOf("killactive") !== -1) {
            binds["closewindow"] = shortcut;
          } else if (tail.indexOf("fullscreen, fullscreen") !== -1 || (tail.indexOf("fullscreen") !== -1 && tail.indexOf("1") === -1 && !binds["fullscreen"])) {
            binds["fullscreen"] = shortcut;
          } else if (tail.indexOf("togglesplit") !== -1) {
            binds["togglesplit"] = shortcut;
          } else if (tail.indexOf("togglespecialworkspace") !== -1) {
            binds["togglespecialworkspace"] = shortcut;
          } else if (tail.indexOf("launcher toggle") !== -1 || tail.indexOf("rofi -show drun") !== -1) {
            binds["launcher"] = shortcut;
          } else if (tail.indexOf("$term") !== -1 || tail.indexOf("kitty") !== -1 || tail.indexOf("ghostty") !== -1 || tail.indexOf("Open terminal") !== -1) {
            if (!binds["terminal"]) binds["terminal"] = shortcut;
          } else if (tail.indexOf("ScreenShot.sh --swappy") !== -1 || tail.indexOf("grimblast") !== -1) {
            binds["screenshot"] = shortcut;
          }

          if (tail.indexOf("movetoworkspacesilent") === -1 && tail.indexOf("movetoworkspace") !== -1) {
            for (let ws = 1; ws <= 5; ws++) {
              if (tail.indexOf("movetoworkspace, " + ws) !== -1 || tail.indexOf("movetoworkspace," + ws) !== -1 || tail.indexOf("code:" + (ws + 9)) !== -1) {
                binds["moveto_" + ws] = shortcut;
              }
            }
          }
        }
      }
    };

    parseText(defaultBindsFile.text());
    parseText(userBindsFile.text());

    root.parsedBinds = binds;
    root.bindsUpdateCounter++;
  }

  Timer {
    id: retryTimer
    interval: 150
    running: Object.keys(root.parsedBinds).length === 0
    repeat: true
    onTriggered: {
      root.updateKeybinds();
      if (Object.keys(root.parsedBinds).length > 0) {
        retryTimer.stop();
      }
    }
  }

  Component.onCompleted: {
    root.updateKeybinds();
  }
}
