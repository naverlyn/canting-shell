# canting-shell

*Draw your own palette.*

A personal Hyprland desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/), where the main idea is making the colors yours.

The name comes from the **canting**, the small copper pen used to draw wax patterns in Indonesian batik. Pronounced "chan-ting" (the `c` sounds like "ch"). Just like a batik maker draws their own motif, this shell lets you draw your own palette: pick a curated theme, generate one from your wallpaper, or write your own.

## what's included

| Module | What it does |
|--------|-------------|
| **Bar** | configurable and draggable layout: clock with calendar, workspaces, window title, global menu, volume, network speed, battery, system tray, media player, weather, CPU / memory / disk / temperature, and a cava audio visualizer. Supports multiple bars and per-bar colors |
| **App Launcher** | searchable application launcher, plus a full-screen app grid |
| **Clipboard** | clipboard history manager |
| **Notifications** | notification daemon with popups and a history view |
| **OSD** | on-screen display for volume and brightness |
| **Control Center** | quick settings tiles (Wi-Fi, night light, and more), media, speaker and mic controls, brightness, weather, system info. Tiles and cards can be rearranged |
| **Settings** | Appearance, Bar, Control Center, Wallpaper, Sound, Display, Wi-Fi, Bluetooth, Power, Keyboard, Mouse, Notifications, OSD, Animations, Hyprland, Hyprlock lock screen, and default apps |
| **Theme Switcher** | 200+ curated themes, or a palette generated from your wallpaper with `matugen` or `wallust` |
| **Wallpaper Manager** | wallpaper picker with folder browser and preview, supports `hyprpaper` and `awww` |
| **Monitor Manager** | visual front-end for arranging displays |
| **Idle Inhibitor** | keeps the screen awake while toggled on |

## supported systems

currently supported: **Arch Linux** and **Fedora**.

## prerequisites

- [Quickshell](https://quickshell.outfoxxed.me/) + Qt 6
- [Hyprland](https://hyprland.org/)
- a [Nerd Font](https://www.nerdfonts.com/) (Hack Nerd Font by default)
- `jq`

optional, depending on the features you use:

- `brightnessctl`: brightness control
- `nmcli`: Wi-Fi and network info
- `hyprpaper` or `awww`: setting the wallpaper
- `matugen` or `wallust`: palette from wallpaper
- `hyprlock` and `hypridle`: lock screen and idle settings
- `cava`: audio visualizer
- `hyprsunset`, `wlsunset` or `gammastep`: night light
- `curl`: weather

### works with vanilla Hyprland?

Yes. The shell only needs Hyprland and Quickshell. It was developed on a [JaKooLit](https://github.com/JaKooLit/Hyprland-Dots) setup, so some features detect JaKooLit's files and fall back to plain Hyprland when they aren't there.

- **Keybinds, animations and Hyprland settings:** the Settings app writes to JaKooLit's `UserConfigs/` files if they exist. On vanilla Hyprland it creates its own files (for example `custom_keybinds.conf`) and adds a `source = ...` line to your `hyprland.conf`.
- **Control Center tiles:** Game Mode, Dark/Light, and Emoji call JaKooLit scripts in `~/.config/hypr/scripts/`, so they won't work on vanilla Hyprland unless you provide scripts with those names. Screenshot falls back to `grimblast` or `hyprshot`. Clipboard uses this shell's own clipboard module.
- **Lock screen and idle:** these edit `hyprlock.conf` and `hypridle.conf` in `~/.config/hypr/`.

I haven't tested on a fresh vanilla install, so please open an issue if something breaks.

## usage and keybindings

Every module can be controlled from the shell with `qs ipc call <target> <function>`. Bind these in your `hyprland.conf` to get your own shortcuts:

```
bind = SUPER, I, exec, qs ipc call settings toggle
bind = SUPER, D, exec, qs ipc call launcher toggle
bind = SUPER, V, exec, qs ipc call clipboard toggle
```

| Command | What it does |
|---------|-------------|
| `qs ipc call settings toggle` | open or close Settings |
| `qs ipc call settings open <tab>` | open Settings on a page, for example `wifi` or `sound` |
| `qs ipc call launcher toggle` | app launcher |
| `qs ipc call appgrid toggle` | full-screen app grid |
| `qs ipc call clipboard toggle` | clipboard history (also `open` and `close`) |
| `qs ipc call bar toggle` | show or hide the bar |
| `qs ipc call theme toggle` | theme switcher |
| `qs ipc call theme wallpaper /path/to/image.png` | generate a palette from an image |
| `qs ipc call wallpaper toggle` | wallpaper picker |
| `qs ipc call wallpaper addFolder /path` | add a wallpaper folder (also `removeFolder`, `rescan`) |
| `qs ipc call monitors toggle` | monitor manager (also `refresh`) |
| `qs ipc call notifications dismiss_all` | dismiss all notifications |
| `qs ipc call notifications dnd_toggle` | toggle Do Not Disturb (also `dnd_off`) |
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
