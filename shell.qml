//@ pragma UseQApplication
//@ pragma Env QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

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
}
