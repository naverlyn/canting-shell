import QtQuick
import "../Widgets"

Item {
  id: registry
  visible: false
  width: 0
  height: 0

  required property var hostRoot
  required property var hostContainer
  required property var hostWindow
  required property var hostScope

  // 1. Applications Launcher Button
  Component {
    id: appGridComp
    AppLauncherButton {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
      hostWindow: registry.hostWindow
      hostScope: registry.hostScope
    }
  }

  // 2. CPU Usage Pill
  Component {
    id: cpuComp
    CpuUsagePill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 3. CPU Temperature Pill
  Component {
    id: tempComp
    CpuTemperaturePill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 4. Memory (RAM) Pill
  Component {
    id: memoryComp
    MemoryUsagePill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 5. Disk Usage Pill
  Component {
    id: diskComp
    DiskUsagePill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 6. Active Window Title
  Component {
    id: windowTitleComp
    WindowTitleLabel {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // Global Menu (AppMenu / Menu Title)
  Component {
    id: globalMenuComp
    GlobalMenu {
      barContainer: registry.hostContainer
      theme: registry.hostRoot.theme
      font: registry.hostRoot.font
    }
  }

  Component {
    id: workspacesComp
    WorkspacesWidget {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 8. Weather Info Pill
  Component {
    id: weatherComp
    WeatherPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 9. Clock & Calendar Popup
  Component {
    id: clockComp
    ClockCalendarPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 10. System Tray
  Component {
    id: trayComp
    SystemTrayWidget {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  Component {
    id: controlCenterComp
    ControlCenterButton {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
      hostWindow: registry.hostWindow
      hostScope: registry.hostScope
    }
  }

  Component {
    id: notificationsComp
    NotificationsButton {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
      hostWindow: registry.hostWindow
      hostScope: registry.hostScope
    }
  }

  // 12. Network Upload & Download Speed Pill
  Component {
    id: networkComp
    NetworkSpeedPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 13. Battery Status Pill
  Component {
    id: batteryComp
    BatteryPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 14. Audio Volume Pill
  Component {
    id: volumeComp
    VolumePill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 15. Media Player (MPRIS) Pill
  Component {
    id: mediaComp
    MediaPlayerPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 16. Idle Inhibitor (Caffeine) Pill
  Component {
    id: idleInhibitorComp
    IdleInhibitorButton {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 17. Cava Audio Spectrum Visualizer Pill
  Component {
    id: cavaComp
    CavaVisualizerPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 18. GPU Usage Pill
  Component {
    id: gpuComp
    GpuUsagePill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 19. Wi-Fi Pill
  Component {
    id: wifiComp
    WifiPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 19b. Bluetooth Pill
  Component {
    id: bluetoothComp
    BluetoothPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 20. Brightness Pill
  Component {
    id: brightnessComp
    BrightnessPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 21. Hyprland Layout Switcher Pill
  Component {
    id: hyprLayoutComp
    HyprLayoutPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // 22. Custom Script Pill
  Component {
    id: customScriptComp
    CustomScriptPill {
      hostRoot: registry.hostRoot
      hostContainer: registry.hostContainer
    }
  }

  // Widget component resolver
  function getWidgetComponent(widgetId) {
    switch (widgetId) {
      case "appGrid": return appGridComp;
      case "cpu": return cpuComp;
      case "gpu": return gpuComp;
      case "temp": return tempComp;
      case "memory": return memoryComp;
      case "disk": return diskComp;
      case "network": return networkComp;
      case "wifi":
      case "wifiBluetooth": return wifiComp;
      case "bluetooth": return bluetoothComp;
      case "brightness": return brightnessComp;
      case "battery": return batteryComp;
      case "volume": return volumeComp;
      case "media": return mediaComp;
      case "cava": return cavaComp;
      case "hyprLayout": return hyprLayoutComp;
      case "customScript": return customScriptComp;
      case "idleInhibitor": return idleInhibitorComp;
      case "windowTitle": return windowTitleComp;
      case "globalMenu": return globalMenuComp;
      case "workspaces": return workspacesComp;
      case "weather": return weatherComp;
      case "clock": return clockComp;
      case "tray": return trayComp;
      case "controlCenter": return controlCenterComp;
      case "notifications": return notificationsComp;
      default: return null;
    }
  }
}
