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


  // property string memoryUsage: "0.0 / 0 GiB (-100%)"
  property string diskUsage: "Loading..."
  property string weatherInfo: "Loading..."


  property var _prevCpu: null
  property bool hasBattery: false

  // Check if hardware battery exists
  Process {
    id: checkBatteryProc
    command: ["sh", "-c", "ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        root.hasBattery = text.trim() !== "";
        if (root.hasBattery) batteryProc.running = true;
      }
    }
  }

  // CPU Usage via /proc/stat (instantaneous, 0% CPU overhead, no heavy process scan)
  Process {
    id: cpuProc
    command: ["head", "-n", "1", "/proc/stat"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(/\s+/);
        if (parts.length >= 5) {
          const user = parseInt(parts[1]) || 0;
          const nice = parseInt(parts[2]) || 0;
          const system = parseInt(parts[3]) || 0;
          const idle = parseInt(parts[4]) || 0;
          const iowait = parseInt(parts[5]) || 0;
          const irq = parseInt(parts[6]) || 0;
          const softirq = parseInt(parts[7]) || 0;
          const steal = parseInt(parts[8]) || 0;

          const total = user + nice + system + idle + iowait + irq + softirq + steal;
          const work = user + nice + system + irq + softirq + steal;

          if (root._prevCpu) {
            const totalDiff = total - root._prevCpu.total;
            const workDiff = work - root._prevCpu.work;
            if (totalDiff > 0) {
              const pct = Math.round((workDiff / totalDiff) * 100);
              root.cpuUsage = Math.min(100, Math.max(0, pct)) + "%";
            }
          }
          root._prevCpu = { total: total, work: work };
        }
      }
    }
  }

  // Memory Usage
  Process {
    id: memProc
    command: ["sh", "-c", "free -m | awk '/Mem:/ {printf \"%.1f/%.1f GiB (%.0f%%)\", $3/1024, $2/1024, ($3/$2)*100}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.memoryUsage = text.trim();
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

  // Battery (only polled if hardware battery is present)
  Process {
    id: batteryProc
    command: ["sh", "-c", "printf '%s\\n%s' \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo '99')\" \"$(cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo 'Discharging')\""]
    running: false

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

  // Temperature via sysfs hwmon with sensors fallback
  Process {
    id: tempProc
    command: ["sh", "-c", "t=$(cat /sys/class/hwmon/hwmon1/temp1_input 2>/dev/null || cat /sys/class/hwmon/hwmon0/temp1_input 2>/dev/null || cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null); if [ -n \"$t\" ]; then echo \"$(( t / 1000 ))°C\"; else sensors 2>/dev/null | grep -E 'Package id 0|Tctl' | head -1 | awk '{print $2}' | sed 's/+//'; fi"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.temperature = text.trim() || "N/A"
      }
    }
  }

  // Weather app (fetched at startup and refreshed every 15 min, not every 2s)
  Process {
    id: weatherProc
    command: ["curl", "-s", "--connect-timeout", "5", "wttr.in/Bekasi?format=4"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const val = text.trim();
        if (val !== "") root.weatherInfo = val;
      }
    }
  }

  // Disk (checked every 60s, not every 2s)
  Process {
    id: diskProc
    command: ["sh", "-c", "df -h / /home 2>/dev/null | awk 'NR>1 {printf \"%s (%s) \", $6, $5}' | sed 's/ $//'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.diskUsage = text.trim();
      }
    }
  }

  // Fast update timer: CPU, Mem, Temp (every 2s)
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      cpuProc.running = true
      memProc.running = true
      tempProc.running = true
    }
  }

  // Network timer (every 10s)
  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: {
      netProc.running = true
      if (root.hasBattery) batteryProc.running = true
    }
  }

  // Disk usage timer (every 60s)
  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: {
      diskProc.running = true
    }
  }

  // Weather refresh timer (every 15 minutes)
  Timer {
    interval: 900000
    running: true
    repeat: true
    onTriggered: {
      weatherProc.running = true
    }
  }
}
