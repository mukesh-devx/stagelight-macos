# StageLight for macOS

> **Theatrical Ambient Focus Dimmer & Spotlight for macOS.**  
> Effortlessly eliminates glare, clutter, and eye fatigue on large 4K & Ultrawide displays.

---

## The Problem It Solves

On large 27-inch 4K or ultrawide monitors (e.g. 3840×2160), having multiple windows open creates severe visual noise, brightness glare, and distraction. Inactive white backgrounds (browsers, documentation, spreadsheets) strain your eyes while you are trying to focus on code or writing.

**StageLight** dims all background clutter, inactive windows, desktop icons, and secondary displays with a soft, cinematic dark veil (20%–80% opacity), keeping the currently active window spotlighted with an Apple-style glowing accent border.

---

## Highlights

- **100% Zero-Latency Click-Through**: Background windows are dimmed, but clicks pass through immediately with no double-clicking required. Clicking any dimmed window instantly focuses it and moves the spotlight.
- **60–120 FPS Fluid Motion**: Window dragging and resizing track smoothly across high-refresh displays.
- **Native Apple Bezel HUD**: On-screen capsule notifications and slider HUDs styled after macOS system bezels.
- **Multi-Display Awareness**: Automatically dims secondary screens or spans cutouts across displays.
- **Apple Menu Bar Utility**: Quick switcher for presets, dimming levels, accent colors, and display preferences.
- **Native Fullscreen Handling**: Automatically steps out of the way when an app enters native fullscreen mode.
- **0.0% Idle CPU**: Built directly on native CoreGraphics canvas layers.

---

## Keyboard Shortcuts

| Shortcut | Action | Description |
|---|---|---|
| **`⌥ D`** | **Toggle StageLight** | Instantly enable or pause the spotlight dimmer |
| **`⌥ ]`** | **Increase Dimming** | Deepen background dimming by +5% |
| **`⌥ [`** | **Decrease Dimming** | Lighten background dimming by -5% |
| **`⌥ \`** | **Cycle Accent Color** | Switch between Blue, Purple, Green, Orange, and Slate |

---

## Dimming Presets

Choose your focus level directly from the menu bar:

- **Soft (25%)**: Gentle reduction of background distraction during daytime reading and office tasks.
- **Balanced (42%)** *(Default)*: The ideal sweet spot—inactive content remains legible without fighting for your attention.
- **Cinema (65%)**: High contrast theatrical focus for deep concentration and dark rooms.
- **Studio Dark (80%)**: Laser-sharp tunnel vision for late-night programming or writing sprints.

---

## Installation

### Prerequisites

- macOS 12+ (tested on Sonoma & Sequoia)
- [Hammerspoon](https://www.hammerspoon.org/) installed and running.

### 1-Step Setup

Clone the repository and run the installer:

```bash
cd "stagelight-hammerspoon"
./install.sh
```

The script symlinks `stagelight` into `~/.hammerspoon/stagelight`, enables it in `~/.hammerspoon/init.lua`, and reloads your config.

---

## Configuration

You can customize StageLight in your `~/.hammerspoon/init.lua`:

```lua
local stagelight = require("stagelight")

stagelight.start({
  dimOpacity = 0.42,          -- Default dimming level (0.10 to 0.90)
  glowBorder = true,          -- Apple-style glowing border
  borderWidth = 2.0,          -- Border thickness in points
  accentColorName = "blue",   -- "blue", "purple", "green", "orange", or "slate"
  dimInactiveScreens = true,  -- Dim secondary monitors
  dimMenuBarAndDock = false,  -- Keep macOS menu bar and dock bright
  autoHideFullScreen = true,  -- Auto-pause when an app is fullscreen
})
```

---

## Uninstallation

To remove StageLight cleanly:

```bash
./install.sh --uninstall
```

---

## License

MIT License. Crafted for clean, distraction-free productivity on macOS.
