<div align="center">

# 💡 StageLight for macOS

**Theatrical Ambient Focus Dimmer & Spotlight for macOS.**  
*Eliminate glare, visual clutter, and eye strain on 4K, 5K & Ultrawide displays.*

[![macOS](https://img.shields.io/badge/macOS-12.0+-blue?style=flat-square&logo=apple&logoColor=white)](https://apple.com/macos)
[![Hammerspoon](https://img.shields.io/badge/Hammerspoon-1.0+-orange?style=flat-square&logo=lua&logoColor=white)](https://www.hammerspoon.org)
[![Click-Through](https://img.shields.io/badge/Click--Through-100%25%20Immediate-success?style=flat-square)](https://github.com/mukesh-devx/stagelight-macos)
[![CPU: 0% Idle](https://img.shields.io/badge/CPU-0%25%20Idle-brightgreen?style=flat-square)](https://github.com/mukesh-devx/stagelight-macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

[Why StageLight?](#-the-problem-it-solves) • [Features](#-features) • [Shortcuts](#%EF%B8%8F-keyboard-shortcuts) • [Presets](#-focus-presets) • [Installation](#-installation) • [Configuration](#%EF%B8%8F-configuration) • [Comparison](#-comparison)

---

</div>

## 🎯 The Problem it Solves

On large **27-inch 4K**, **5K Studio Displays**, and **Ultrawide monitors** (e.g. 3840×2160):

1. **The 4K White Glare & Distraction Trap**: You are editing code or writing in a focused window, while 5 other background windows (bright browser documentation, chat apps, file finders) surround your screen with blinding white light and visual distraction.
2. **The "Broken Click-Through" of Legacy Dimmers**: Traditional focus apps overlay semi-transparent windows that intercept mouse clicks, forcing you to click twice just to activate a background app.
3. **Sluggish Window Dragging**: Many dimmer tools lag heavily when dragging windows across high-refresh (120Hz ProMotion or 4K) displays.

**StageLight solves this with theatrical precision.** It casts an ambient, dark acrylic veil over all background windows, desktop clutter, and secondary displays, highlighting your active window with an Apple-style glowing accent border.

---

## 🎭 The StageLight Architecture

Unlike traditional dimmers that create a single translucent window over your whole screen, StageLight uses a **4-Rectangle Geometric Hole-Punch** rendered directly via macOS CoreGraphics:

```
┌────────────────────────────────────────────────────────┐
│               Top Dimming Rectangle                    │
├───────────────┬────────────────────────┬───────────────┤
│   Left Dim    │   ⭐ FOCUSED WINDOW    │   Right Dim   │
│   Rectangle   │   (100% Brightness     │   Rectangle   │
│               │    + Apple Halo Glow)  │               │
├───────────────┴────────────────────────┴───────────────┤
│              Bottom Dimming Rectangle                  │
└────────────────────────────────────────────────────────┘
```

Because the active window region is completely hole-punched, and mouse interception is disabled (`canvasMouseEvents = false`), **every click passes immediately to the window beneath it**. Clicking any background window focuses it on the very first click with **zero latency**!

---

## ✨ Features

- **⚡️ 100% Immediate Click-Through**: No double-clicking. Background windows are dimmed, but clicks pass through natively.
- **✨ Apple-Grade Glowing Accent Border**: Highlights the active window with a crisp rounded border (`10pt` radius) and a soft ambient halo matching macOS Sonoma & Sequoia aesthetics.
- **💎 Native Apple Bezel HUD**: When toggling or adjusting brightness, a frosted glass capsule bezel pops up in the screen center with a live progress bar.
- **🚀 60–120 FPS Fluid Drag Tracking**: Nanosecond-throttled move handlers ensure buttery smooth tracking while you drag or resize windows.
- **🖥️ Multi-Display Awareness**: Automatically dims secondary monitors when you focus a window on your primary 4K screen, and vice versa.
- **🎛️ Native macOS Menu Bar Utility**: Quick preset switching, opacity sliders, accent color choices, and display settings right in your menu bar.
- **🌌 Fullscreen & Desktop Intelligence**: Automatically fades out when you enter native macOS fullscreen or click on the empty desktop wallpaper.
- **🔋 Zero Battery Drain (0.0% Idle CPU)**: Consumes virtually zero memory and 0% CPU when not actively transitioning windows.

---

## ⌨️ Keyboard Shortcuts

StageLight works out of the box with intuitive macOS shortcuts:

| Shortcut | Action | Description |
|---|---|---|
| <kbd>⌥ Option</kbd> + <kbd>D</kbd> | **Toggle StageLight** | Instantly enable or pause the ambient dimmer |
| <kbd>⌥ Option</kbd> + <kbd>]</kbd> | **Dim More (+5%)** | Increases background dimming depth (shows live slider HUD) |
| <kbd>⌥ Option</kbd> + <kbd>[</kbd> | **Dim Less (-5%)** | Lightens background dimming for daylight hours |
| <kbd>⌥ Option</kbd> + <kbd>\</kbd> | **Cycle Accent Color** | Instantly swaps between 5 Apple-tuned accent colors |

---

## 🎚 Focus Presets

Switch between theatrical presets right from the Menu Bar or hotkeys:

| Preset | Opacity | Ideal For |
|---|---|---|
| **Soft** | `25%` | Daytime office work, reading articles, writing documentation. |
| **Balanced** *(Default)* | `42%` | The golden ratio—background is noticeably recessed without losing readability. |
| **Cinema** | `65%` | High-contrast theatrical spotlight for evening work and dark rooms. |
| **Studio Dark** | `80%` | Extreme laser focus and tunnel vision for late-night coding sprints. |

---

## 🎨 Accent Glow Themes

Choose from 5 curated Apple-style neon accents:

- 🔵 **Electric Blue** (`#0A84FF`) - Default macOS system accent
- 🟣 **Lavender Purple** (`#BF5AF2`) - Deep creative flow
- 🟢 **Cyber Green** (`#30D158`) - Terminal & code aesthetic
- 🟠 **Sunset Orange** (`#FF9F0A`) - Warm evening ambient tone
- ⚪️ **Minimal Slate** (`#8E8E93`) - Subtle, monochromatic luxury

---

## 📋 Requirements

- **macOS 12.0 (Monterey)**, **13 (Ventura)**, **14 (Sonoma)**, or **15 (Sequoia)**
- [Hammerspoon](https://www.hammerspoon.org/) 1.0+ (Free, open-source macOS automation engine)
  ```sh
  brew install --cask hammerspoon
  ```

---

## 🚀 Installation

### Automated 1-Click Install

Clone the repository and run the setup script:

```bash
git clone https://github.com/mukesh-devx/stagelight-macos.git
cd stagelight-macos
./install.sh
```

`install.sh` will:
1. Symlink the `stagelight` module into `~/.hammerspoon/stagelight`
2. Safely register StageLight inside your `~/.hammerspoon/init.lua`
3. Reload Hammerspoon automatically

---

## ⚙️ Configuration

StageLight works out of the box with zero setup. If you wish to customize defaults, pass an options table to `stagelight.start()` in your `~/.hammerspoon/init.lua`:

```lua
local stagelight = require("stagelight")

stagelight.start({
  -- Dimming appearance
  dimOpacity = 0.42,          -- Default dimming (0.10 to 0.90)
  dimColor = "#000000",       -- Deep black background veil
  dimMenuBarAndDock = false,  -- Keep macOS menu bar & dock bright (true = cinema mode)
  dimInactiveScreens = true,  -- Dim secondary displays

  -- Active window spotlight glow
  glowBorder = true,          -- Apple-style glowing border
  borderWidth = 2.0,          -- Border thickness in points
  borderRadius = 10,          -- Corner curve matching macOS windows (10pt)
  accentColorName = "blue",   -- "blue", "purple", "green", "orange", "slate"

  -- Behavior
  autoHideFullScreen = true,  -- Step aside when active app enters macOS fullscreen
  showHUD = true,             -- Show Apple bezel HUD on hotkey / preset toggle
  menubar = true,             -- Show status item in macOS menu bar

  -- Custom Hotkeys
  hotkeys = {
    toggle = { { "alt" }, "d" },
    increaseOpacity = { { "alt" }, "]" },
    decreaseOpacity = { { "alt" }, "[" },
    cycleAccent = { { "alt" }, "\\" },
  },
})
```

---

## ⚔️ Comparison

| Feature | StageLight | HazeOver (Paid) | Isolator (Deprecated) | Built-in macOS Focus |
|---|:---:|:---:|:---:|:---:|
| **Cost** | **100% Free & Open Source** | $4.99 - $9.99 | Free (Unmaintained) | Free |
| **Immediate 1st-Click Pass-Through** | **Yes (0ms)** | No (interception delay) | No | N/A |
| **Apple-Style Glow Halo** | **Yes (Customizable)** | No | No | No |
| **Apple Bezel HUD** | **Yes (Capsule + Slider)** | No | No | No |
| **Native Menu Bar App** | **Yes** | Yes | Broken on modern macOS | No |
| **Multi-Display Dimming** | **Yes** | Yes | Buggy on dual monitors | No |
| **Resource Usage** | **0.0% CPU Idle** | Low | High | 0% |
| **Custom Color Accents** | **5 Curated Themes** | Limited | None | None |

---

## 🏗 Codebase Architecture

```
stagelight-hammerspoon/
├── stagelight/
│   ├── init.lua       # Lifecycle, window watchers, hotkey bindings
│   ├── dimmer.lua     # 4-rectangle cutout canvas & multi-screen coordinator
│   ├── hud.lua        # Apple Bezel capsule HUD & progress slider
│   ├── menubar.lua    # Native macOS menu bar status item & dynamic menus
│   ├── config.lua     # Presets, color palette, and persistent settings
│   ├── util.lua       # Geometry, hex colors, and menu bar template icon
│   └── log.lua        # Formatted logger
├── install.sh         # 1-click symlink installer and uninstaller
├── README.md          # Visual documentation and user guide
└── LICENSE            # MIT License
```

---

## 🧹 Uninstallation

To cleanly remove StageLight at any time:

```bash
./install.sh --uninstall
```

This safely removes the module symlink and cleans up your `~/.hammerspoon/init.lua` with an automatic backup.

---

## 📄 License

Released under the [MIT License](LICENSE). Built for clean, distraction-free focus on Apple Silicon & macOS.
