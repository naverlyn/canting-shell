pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string cpuUsage: "0%"
  property string memoryUsage: "0%"
  property string networkInfo: "Disconnected"
  property string networkType: "disconnected"
  property int batteryLevelRaw: 0
  property string batteryLevel: "0%"
  property string batteryIcon: "󰂎"
  property bool batteryCharging: false
  property string temperature: "0°C"
  property string diskUsage: "0%"
  property string weatherInfo: "Loading..."

  // CPU Usage
  Process {
    id: cpuProc
    command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1\"%\"}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.cpuUsage = text.trim()
      }
    }
  }

  // Memory Usage
  Process {
    id: memProc
    command: ["sh", "-c", "free | grep Mem | awk '{printf \"%.1f%%\", ($3/$2) * 100.0}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.memoryUsage = text.trim()
      }
    }
  }

  // Network Info (ethernet takes priority over wifi)
  Process {
    id: netProc
    command: ["sh", "-c", "eth=$(nmcli -t -f type,state dev 2>/dev/null | grep '^ethernet:connected'); if [ -n \"$eth\" ]; then echo 'ethernet:Ethernet'; else wifi=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2); if [ -n \"$wifi\" ]; then echo \"wifi:$wifi\"; else echo 'disconnected:'; fi; fi"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const result = text.trim()
        const colonIdx = result.indexOf(':')
        const type = result.substring(0, colonIdx)
        const info = result.substring(colonIdx + 1)
        root.networkType = type
        root.networkInfo = info || "Disconnected"
      }
    }
  }

  // Battery
  Process {
    id: batteryProc
    command: ["sh", "-c", "printf '%s\\n%s' \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo '99')\" \"$(cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo 'Discharging')\""]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n")
        const level = parseInt(lines[0]) || 0
        const status = (lines[1] || "Discharging").trim()

        root.batteryLevelRaw = level
        root.batteryLevel = level + "%"
        root.batteryCharging = status === "Charging"

        if (root.batteryCharging) root.batteryIcon = ""
        else if (level >= 90) root.batteryIcon = "󰁹"
        else if (level >= 80) root.batteryIcon = "󰂂"
        else if (level >= 70) root.batteryIcon = "󰂁"
        else if (level >= 60) root.batteryIcon = "󰂀"
        else if (level >= 50) root.batteryIcon = "󰁿"
        else if (level >= 40) root.batteryIcon = "󰁾"
        else if (level >= 30) root.batteryIcon = "󰁽"
        else if (level >= 20) root.batteryIcon = "󰁼"
        else if (level >= 10) root.batteryIcon = "󰁻"
        else root.batteryIcon = "󰁺"
      }
    }
  }

  // Temperature
  Process {
    id: tempProc
    command: ["sh", "-c", "sensors 2>/dev/null | grep -E 'Package id 0|Tctl' | head -1 | awk '{print $2}' | sed 's/+//' || echo 'N/A'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.temperature = text.trim() || "N/A"
      }
    }
  }

  // Disk Usage
  Process {
    id: diskProc
    command: ["sh", "-c", "df -h / | awk 'NR==2 {print $(NF-1)}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const res = text.trim()
        if (res) root.diskUsage = res
      }
    }
  }

  // Weather Info
  Process {
    id: weatherProc
    command: ["sh", "-c", "w=$(curl -s --connect-timeout 5 'wttr.in/Bekasi?format=4' 2>/dev/null | grep -v '<' | tr -d '\\n' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'); [ -n \"$w\" ] && echo \"$w\" || echo '󰖐 N/A'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const res = text.trim()
        if (res && res.length > 0 && !res.includes("Unknown location") && !res.includes("500 Internal") && !res.includes("502 Bad") && !res.includes("503 Service") && !res.includes("404 Not")) {
          root.weatherInfo = res
        } else if (!root.weatherInfo || root.weatherInfo === "Loading...") {
          root.weatherInfo = "󰖐 N/A"
        }
      }
    }
  }

  function refreshWeather() {
    weatherProc.running = true
  }

  function refreshDisk() {
    diskProc.running = true
  }

  // Update timer (fast polling for CPU, Mem, Net, Battery, Temp)
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      cpuProc.running = true
      memProc.running = true
      netProc.running = true
      batteryProc.running = true
      tempProc.running = true
    }
  }

  // Disk update timer (every 30 seconds)
  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: {
      diskProc.running = true
    }
  }

  // Weather update timer (every 15 minutes)
  Timer {
    interval: 900000
    running: true
    repeat: true
    onTriggered: {
      weatherProc.running = true
    }
  }
}
