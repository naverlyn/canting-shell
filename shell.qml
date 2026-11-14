//@ pragma Env QT_LOGGING_RULES=qt.svg*=false;qt.svg.warning=false;qt.svg.draw.warning=false;qt.qpa.wayland.textinput.warning=false;qt.qpa.services.warning=false
//@ pragma Env QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env QT_IM_MODULE=compose
//@ pragma Env QT_IM_MODULES=compose
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env MALLOC_ARENA_MAX=4
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import QtQuick
import "bar"
import "AppLauncher"
import "notifications"
import "ThemeSwitcher"
import "wallpaper"
import "osd"
import "MonitorManager"
import "IdleInhibitor"
import "Settings"
import "Clipboard"
import "Lockscreen"

Scope {
  ThemeSwitcher { id: ts }
  Bar { theme: ts.theme }
  AppLauncher { theme: ts.theme }
  AppGrid { theme: ts.theme }
  SettingsApp { theme: ts.theme }
  NotificationPopup { theme: ts.theme }
  WallpaperManager { theme: ts.theme }
  ClipboardManager { theme: ts.theme }
  OSD { theme: ts.theme }
  MonitorManager { theme: ts.theme }
  CaffeineToggle { theme: ts.theme }
  Lockscreen { theme: ts.theme }
}
