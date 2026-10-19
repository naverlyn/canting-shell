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
  property string networkDownSpeed: "0 B/s"
  property string networkUpSpeed: "0 B/s"
  property string networkDownCompact: "0B"
  property string networkUpCompact: "0B"
  property int batteryLevelRaw: 0
  property string batteryLevel: "0%"
  property string batteryIcon: "󰂎"
  property bool batteryCharging: false
  property string temperature: "0°C"
  property string diskUsage: "0%"
  property string weatherInfo: "Loading..."
  property bool idleInhibited: false

  function toggleIdleInhibitor() {
    root.idleInhibited = !root.idleInhibited;
  }

  function setIdleInhibitor(active) {
    root.idleInhibited = Boolean(active);
  }

  property real _prevCpuTotal: 0
  property real _prevCpuIdle: 0
  property real _prevNetRx: -1
  property real _prevNetTx: -1
  property real _prevNetTime: 0

  function formatSpeed(bytesPerSec, compact) {
    if (isNaN(bytesPerSec) || bytesPerSec < 0) bytesPerSec = 0;
    if (bytesPerSec >= 1048576) {
      const v = (bytesPerSec / 1048576).toFixed(1).replace(/\.0$/, "");
      return compact ? (v + "M") : (v + " MB/s");
    } else if (bytesPerSec >= 1024) {
      const v = Math.round(bytesPerSec / 1024);
      return compact ? (v + "K") : (v + " KB/s");
    } else {
      const v = Math.round(bytesPerSec);
      return compact ? (v + "B") : (v + " B/s");
    }
  }

  // Consolidated fast-polling process (CPU, Memory, Network, Battery, Temperature)
  Process {
    id: fastStatsProc
    command: [
      "sh", "-c",
      "head -n 1 /proc/stat; " +
      "awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {if (t>0) printf \"MEM:%.1f%%\\n\", ((t-a)/t)*100.0; else print \"MEM:0%\"}' /proc/meminfo; " +
      "awk 'NR>2 {sub(/:/, \"\", $1); if ($1 != \"lo\") {rx += $2; tx += $10}} END {printf \"NETBW:%.0f:%.0f\\n\", rx, tx}' /proc/net/dev; " +
      "net_t=\"disconnected\"; net_i=\"\"; " +
      "for dev in /sys/class/net/*; do " +
      "[ \"$(basename \"$dev\")\" = \"lo\" ] && continue; " +
      "if [ -f \"$dev/carrier\" ] && [ \"$(cat \"$dev/carrier\" 2>/dev/null)\" = \"1\" ]; then " +
      "n=\"$(basename \"$dev\")\"; " +
      "if [ -d \"$dev/wireless\" ] || [ -f \"$dev/phy80211/name\" ] || [ \"${n#wl}\" != \"$n\" ]; then " +
      "net_t=\"wifi\"; net_i=\"$n\"; " +
      "if command -v iwgetid >/dev/null 2>&1; then s=$(iwgetid -r \"$n\" 2>/dev/null || true); [ -n \"$s\" ] && net_i=\"$s\"; fi; " +
      "break; " +
      "else net_t=\"ethernet\"; net_i=\"Ethernet\"; break; fi; fi; done; " +
      "if [ \"$net_t\" = \"wifi\" ] && [ \"$net_i\" = \"$n\" ] && command -v nmcli >/dev/null 2>&1; then " +
      "s=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1==\"yes\"{print $2; exit}'); [ -n \"$s\" ] && net_i=\"$s\"; fi; " +
      "echo \"NET:$net_t:$net_i\"; " +
      "printf 'BAT:%s:%s\\n' \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '99')\" \"$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo 'Discharging')\"; " +
      "t=\"\"; for f in /sys/class/hwmon/hwmon*/temp1_input /sys/class/thermal/thermal_zone*/temp; do " +
      "if [ -f \"$f\" ]; then v=$(cat \"$f\" 2>/dev/null || true); if [ -n \"$v\" ] && [ \"$v\" -gt 0 ] 2>/dev/null; then t=\"$((v / 1000))°C\"; break; fi; fi; done; " +
      "if [ -z \"$t\" ]; then t=$(sensors 2>/dev/null | grep -E 'Package id 0|Tctl|Composite' | head -1 | awk '{print $2}' | sed 's/+//' || true); fi; " +
      "echo \"TEMP:${t:-N/A}\""
    ]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i].trim()
          if (line.startsWith("cpu ")) {
            const parts = line.split(/\s+/)
            if (parts.length >= 5) {
              let total = 0
              for (let j = 1; j < parts.length; j++) {
                total += parseInt(parts[j]) || 0
              }
              const idle = (parseInt(parts[4]) || 0) + (parseInt(parts[5]) || 0)
              if (root._prevCpuTotal > 0 && total > root._prevCpuTotal) {
                const totalDelta = total - root._prevCpuTotal
                const idleDelta = idle - root._prevCpuIdle
                const pct = Math.max(0, Math.min(100, ((totalDelta - idleDelta) / totalDelta) * 100))
                root.cpuUsage = pct.toFixed(1).replace(/\.0$/, "") + "%"
              }
              root._prevCpuTotal = total
              root._prevCpuIdle = idle
            }
          } else if (line.startsWith("MEM:")) {
            root.memoryUsage = line.substring(4)
          } else if (line.startsWith("NETBW:")) {
            const rest = line.substring(6)
            const parts = rest.split(":")
            const rx = parseFloat(parts[0]) || 0
            const tx = parseFloat(parts[1]) || 0
            const now = Date.now()
            if (root._prevNetRx >= 0 && root._prevNetTime > 0 && now > root._prevNetTime) {
              const dt = (now - root._prevNetTime) / 1000.0
              const rxRate = Math.max(0, (rx - root._prevNetRx) / dt)
              const txRate = Math.max(0, (tx - root._prevNetTx) / dt)
              root.networkDownSpeed = root.formatSpeed(rxRate, false)
              root.networkUpSpeed = root.formatSpeed(txRate, false)
              root.networkDownCompact = root.formatSpeed(rxRate, true)
              root.networkUpCompact = root.formatSpeed(txRate, true)
            }
            root._prevNetRx = rx
            root._prevNetTx = tx
            root._prevNetTime = now
          } else if (line.startsWith("NET:")) {
            const rest = line.substring(4)
            const colonIdx = rest.indexOf(":")
            const type = rest.substring(0, colonIdx)
            const info = rest.substring(colonIdx + 1)
            root.networkType = type
            root.networkInfo = info || "Disconnected"
          } else if (line.startsWith("BAT:")) {
            const rest = line.substring(4)
            const colonIdx = rest.indexOf(":")
            const level = parseInt(rest.substring(0, colonIdx)) || 0
            const status = (rest.substring(colonIdx + 1) || "Discharging").trim()

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
          } else if (line.startsWith("TEMP:")) {
            root.temperature = line.substring(5) || "N/A"
          }
        }
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
    command: ["sh", "-c", "loc=\"" + (BarConfig.weatherLocation || "Bekasi") + "\"; w=$(curl -s --connect-timeout 5 \"wttr.in/${loc}?format=4\" 2>/dev/null | grep -v '<' | tr -d '\\n' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'); [ -n \"$w\" ] && echo \"$w\" || echo '󰖐 N/A'"]
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
    const loc = BarConfig.weatherLocation || "Bekasi";
    const u = BarConfig.weatherUnit === "u" ? "u" : "m";
    weatherProc.command = ["sh", "-c", "loc=\"" + loc + "\"; w=$(curl -s --connect-timeout 5 \"wttr.in/${loc}?format=4&" + u + "\" 2>/dev/null | grep -v '<' | tr -d '\\n' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'); [ -n \"$w\" ] && echo \"$w\" || echo '󰖐 N/A'"];
    weatherProc.running = true;
  }

  function refreshDisk() {
    diskProc.running = true
  }

  // Update timer (fast polling for CPU, Mem, Net, Battery, Temp)
  Timer {
    interval: Math.max(1, (BarConfig.hwPollInterval || 2)) * 1000
    running: true
    repeat: true
    onTriggered: {
      if (!fastStatsProc.running) fastStatsProc.running = true
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

  // Weather update timer (configurable interval)
  Timer {
    interval: Math.max(5, (BarConfig.weatherIntervalMinutes || 15)) * 60 * 1000
    running: true
    repeat: true
    onTriggered: {
      root.refreshWeather();
    }
  }
}
