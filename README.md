# canting-shell

*Draw your own palette.*

A personal Hyprland desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/), where the main idea is making the colors yours.

The name comes from the **canting**, the small copper pen used to draw wax patterns in Indonesian batik. Pronounced "chan-ting" (the `c` sounds like "ch"). Just like a batik maker draws their own motif, this shell lets you draw your own palette: pick a curated theme, generate one from your wallpaper, or write your own.

## what's included

| Module | What it does |
|--------|-------------|
| **Bar** | configurable and draggable layout: clock with calendar (optional year display), workspaces, window title, global menu, volume, network speed, battery, system tray, media player, weather, CPU / memory / disk / temperature, idle inhibitor, and a cava audio visualizer. Supports multiple bars, per-bar colors, floating bars, fluid cards, and screen borders |
| **App Launcher** | Spotlight-style searchable application launcher with command mode (`>`) and usage-based sorting, plus a full-screen app grid |
| **Clipboard** | clipboard history manager powered by `cliphist` with text/image categories, image thumbnails, and search |
| **Notifications** | notification daemon with customizable toast popups, layout blocks, Do Not Disturb, and a history view |
| **OSD** | customizable on-screen display for volume and brightness |
| **Control Center** | quick settings tiles (Wi-Fi, Bluetooth, night light, dark/light mode, and more), quick launch apps, media, speaker and mic controls, brightness, cava visualizer, weather, system info, and notifications view. Tiles and cards can be rearranged |
| **Lock Screen** | native Quickshell lock screen with PAM authentication, blur/visual filters, and modular building blocks (clock, auth box, weather, media player, CPU / memory / disk / battery / system info, keyboard layout, uptime, custom text/commands) |
| **Settings** | Appearance, Bar, App Launcher, Clipboard, Control Center, Wallpaper, Lock Screen (with interactive stage editor), Sound, Display, Wi-Fi, Bluetooth, Power, Keyboard, Mouse & Touchpad, Notifications, OSD, Animations, Hyprland, Autostart, Default Apps, Backup & Restore, and About |
| **Theme Switcher** | 200+ curated themes, or a harmonized palette generated from your wallpaper with `matugen` or `wallust` (with dark/light mode toggle) |
| **Wallpaper Manager** | wallpaper picker with folder browser and preview, per-display wallpapers, resize modes (fill, fit, stretch, center), scaling filters, and ImageMagick visual effects; supports `awww`, `swww`, and `hyprpaper` |
| **Monitor Manager** | visual front-end for arranging displays, resolution, refresh rate, scale, rotation, and mirroring |
| **Idle Inhibitor** | keeps the screen awake while toggled on |

## supported systems

currently supported: **Arch Linux** and **Fedora**.

## prerequisites

- [Quickshell](https://quickshell.outfoxxed.me/) + Qt 6
- [Hyprland](https://hyprland.org/)
- a [Nerd Font](https://www.nerdfonts.com/) (Lato Nerd Font and JetBrainsMono Nerd Font by default)
- `jq` and `python3`

optional, depending on the features you use:

- `cliphist` and `wl-clipboard`: clipboard history
- `brightnessctl`: brightness control
- `nmcli`: Wi-Fi and network info
- `bluetoothctl`: Bluetooth settings and control
- `awww`, `swww`, or `hyprpaper`: setting the wallpaper
- `imagemagick` (`magick`): wallpaper visual effects
- `matugen` or `wallust`: palette from wallpaper
- `grim`: lock screen screenshot background mode
- `hypridle` (and optionally `hyprlock` as fallback): idle timeout settings
- `cava`: audio visualizer
- `hyprsunset`, `wlsunset` or `gammastep`: night light
- `curl`: weather

### works with vanilla Hyprland?

Yes. The shell only needs Hyprland and Quickshell. It was developed on a [JaKooLit](https://github.com/JaKooLit/Hyprland-Dots) setup, so some features detect JaKooLit's files (as well as `.lua` Hyprland configs) and fall back to plain Hyprland when they aren't there.

- **Keybinds, animations, autostart, and Hyprland settings:** the Settings app writes to JaKooLit's `UserConfigs/` or modular `.lua` `Configs/` files if they exist. On vanilla Hyprland it creates its own files (for example `custom_keybinds.conf` or `custom_hypr.lua`) and adds a `source = ...` or `require` line to your Hyprland config.
- **Control Center tiles:** Game Mode and Emoji call JaKooLit scripts in `~/.config/hypr/scripts/`, so they won't work on vanilla Hyprland unless you provide scripts with those names. Dark/Light and Clipboard use this shell's own theme and clipboard modules. Screenshot falls back to `grimblast` or `hyprshot`.
- **Lock screen and idle:** the lock screen runs natively inside Quickshell (`Lockscreen/scripts/lock.sh` falls back to `hyprlock` if Quickshell isn't running). Idle timeout settings edit `hypridle.conf` in `~/.config/hypr/`.

I haven't tested on a fresh vanilla install, so please open an issue if something breaks.

## usage and keybindings

Every module can be controlled from the shell with `qs ipc call <target> <function>`. Bind these in your `hyprland.conf` or `hyprland.lua` to get your own shortcuts:

**`hyprland.conf`:**
```ini
bind = SUPER, I, exec, qs ipc call settings toggle
bind = SUPER, D, exec, qs ipc call launcher toggle
bind = SUPER, V, exec, qs ipc call clipboard toggle
bind = SUPER, L, exec, qs ipc call lockscreen lock
```

**`hyprland.lua`:**
```lua
hl.bind("SUPER + I", hl.dsp.exec_cmd("qs ipc call settings toggle"))
hl.bind("SUPER + D", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("qs ipc call lockscreen lock"))
```

| Command | What it does |
|---------|-------------|
| `qs ipc call settings toggle` | open or close Settings |
| `qs ipc call settings open <tab>` | open Settings on a page, for example `wifi`, `sound`, `lockscreen`, `clipboard`, or `backup` |
| `qs ipc call launcher toggle` | app launcher |
| `qs ipc call appgrid toggle` | full-screen app grid |
| `qs ipc call clipboard toggle` | clipboard history (also `open` and `close`) |
| `qs ipc call lockscreen lock` | lock the screen (also `unlock`, `toggle`, and `status`) |
| `qs ipc call bar toggle` | show or hide the bar |
| `qs ipc call theme toggle` | theme switcher |
| `qs ipc call theme toggleDarkLight` | toggle between dark and light theme variants |
| `qs ipc call theme wallpaper /path/to/image.png` | generate a palette from an image |
| `qs ipc call wallpaper toggle` | wallpaper picker |
| `qs ipc call wallpaper addFolder /path` | add a wallpaper folder (also `removeFolder`, `rescan`) |
| `qs ipc call monitors toggle` | monitor manager (also `refresh`) |
| `qs ipc call notifications dismiss_all` | dismiss all notifications |
| `qs ipc call notifications dnd_toggle` | toggle Do Not Disturb (also `dnd_off`, `set_position`, `test_toast`) |
| `qs ipc call idle toggle` | idle inhibitor (also `enable` and `disable`) |

Run `qs ipc show` to list every available target and function.

## installing

```bash
git clone https://github.com/naverlyn/canting-shell ~/.config/quickshell
quickshell
```

Quickshell reads from `~/.config/quickshell/` by default.

## making your palette

- **curated themes:** pick one in the Theme Switcher.
- **from a wallpaper:** generate a palette with `matugen` or `wallust`:
  ```
  qs ipc call theme wallpaper /path/to/image.png
  ```
- **your own:** colors live in the theme files. Add a theme by appending to the `themes` array.

## credits

canting-shell is a fork of [doannc2212/quickshell-config](https://github.com/doannc2212/quickshell-config). Many thanks to the original author for the foundation this is built on.

Also thanks to the projects and theme creators behind it:

- [Quickshell](https://quickshell.outfoxxed.me/) and [Hyprland](https://hyprland.org/)
- [Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme) by enkia
- [Catppuccin](https://github.com/catppuccin/catppuccin) by the Catppuccin team
- [Bearded Theme](https://marketplace.visualstudio.com/items?itemName=BeardedBear.beardedtheme) by BeardedBear
- [MonkeyType](https://monkeytype.com/) community themes. Colors were derived from MonkeyType's theme palette.
