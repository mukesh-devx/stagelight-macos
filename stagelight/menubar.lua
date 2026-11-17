--- Native macOS Menu Bar Item for StageLight.
--- Displays status, preset switcher, opacity controls, and Apple-style visual preferences.

local config = require("stagelight.config")
local util = require("stagelight.util")
local hud = require("stagelight.hud")
local dimmer = require("stagelight.dimmer")
local log = require("stagelight.log")

local MenuBar = {}
MenuBar.__index = MenuBar

local statusItem = nil
local onToggleCallback = nil
local onOpacityCallback = nil
local onAccentCallback = nil

--- Set callbacks from main StageLight module
function MenuBar.setCallbacks(callbacks)
  onToggleCallback = callbacks.onToggle
  onOpacityCallback = callbacks.onOpacity
  onAccentCallback = callbacks.onAccent
end

--- Build menu items dynamically on each click
local function buildMenu()
  local menu = {}

  -- 1. Main Toggle
  table.insert(menu, {
    title = config.enabled and "StageLight: Active" or "StageLight: Paused",
    checked = config.enabled,
    fn = function()
      if onToggleCallback then
        onToggleCallback()
      end
    end,
  })

  table.insert(menu, { title = "-" })

  -- 2. Presets Header
  table.insert(menu, {
    title = "PRESETS",
    disabled = true,
  })

  for _, p in ipairs(config.presets) do
    local isMatch = math.abs(config.dimOpacity - p.opacity) < 0.02
    table.insert(menu, {
      title = string.format("%s (%d%%)", p.name, math.floor(p.opacity * 100 + 0.5)),
      checked = isMatch,
      fn = function()
        if onOpacityCallback then
          onOpacityCallback(p.opacity, p.name)
        end
      end,
    })
  end

  table.insert(menu, { title = "-" })

  -- 3. Opacity Submenu
  local opacitySubmenu = {}
  table.insert(opacitySubmenu, {
    title = "Increase Dimming (+5%)       ⌥]",
    fn = function()
      if onOpacityCallback then
        onOpacityCallback(config.dimOpacity + 0.05)
      end
    end,
  })
  table.insert(opacitySubmenu, {
    title = "Decrease Dimming (-5%)       ⌥[",
    fn = function()
      if onOpacityCallback then
        onOpacityCallback(config.dimOpacity - 0.05)
      end
    end,
  })
  table.insert(opacitySubmenu, { title = "-" })

  for pct = 20, 80, 10 do
    local val = pct / 100
    local isCur = math.abs(config.dimOpacity - val) < 0.03
    table.insert(opacitySubmenu, {
      title = string.format("%d%%", pct),
      checked = isCur,
      fn = function()
        if onOpacityCallback then
          onOpacityCallback(val)
        end
      end,
    })
  end

  table.insert(menu, {
    title = string.format("Dimming Level: %d%%", math.floor(config.dimOpacity * 100 + 0.5)),
    menu = opacitySubmenu,
  })

  table.insert(menu, { title = "-" })

  -- 4. Glow Accent Border Submenu
  local glowSubmenu = {}
  table.insert(glowSubmenu, {
    title = "Show Glowing Window Border",
    checked = config.glowBorder,
    fn = function()
      config.glowBorder = not config.glowBorder
      config.save()
      dimmer.update()
      if config.showHUD then
        hud.show(config.glowBorder and "Window Glow: ON" or "Window Glow: OFF", "✨")
      end
    end,
  })
  table.insert(glowSubmenu, { title = "-" })

  local colorKeys = { "blue", "purple", "green", "orange", "slate" }
  for _, k in ipairs(colorKeys) do
    local c = config.accentColors[k]
    if c then
      table.insert(glowSubmenu, {
        title = c.name,
        checked = (config.accentColorName == k and config.glowBorder),
        fn = function()
          if onAccentCallback then
            onAccentCallback(k)
          end
        end,
      })
    end
  end

  table.insert(menu, {
    title = "Spotlight Accent Glow",
    menu = glowSubmenu,
  })

  table.insert(menu, { title = "-" })

  -- 5. Multi-display & Appearance options
  table.insert(menu, {
    title = "Dim Inactive Displays",
    checked = config.dimInactiveScreens,
    fn = function()
      config.dimInactiveScreens = not config.dimInactiveScreens
      config.save()
      dimmer.update()
    end,
  })

  table.insert(menu, {
    title = "Dim Menu Bar & Dock (Cinema Mode)",
    checked = config.dimMenuBarAndDock,
    fn = function()
      config.dimMenuBarAndDock = not config.dimMenuBarAndDock
      config.save()
      dimmer.rebuild()
    end,
  })

  table.insert(menu, {
    title = "Auto-Hide on Fullscreen",
    checked = config.autoHideFullScreen,
    fn = function()
      config.autoHideFullScreen = not config.autoHideFullScreen
      config.save()
      dimmer.update()
    end,
  })

  table.insert(menu, { title = "-" })

  -- 6. Shortcuts Reference
  local shortcutsSubmenu = {
    { title = "Toggle StageLight: ⌥D", disabled = true },
    { title = "Increase Dimming: ⌥]", disabled = true },
    { title = "Decrease Dimming: ⌥[", disabled = true },
    { title = "Cycle Accent Color: ⌥\\", disabled = true },
  }
  table.insert(menu, {
    title = "Keyboard Shortcuts",
    menu = shortcutsSubmenu,
  })

  table.insert(menu, { title = "-" })

  -- 7. About & Quit
  table.insert(menu, {
    title = "About StageLight v1.0",
    fn = function()
      hs.alert.show("StageLight v1.0\nAmbient Focus Dimmer for macOS\nDesigned for 4K & Ultrawide Displays")
    end,
  })

  return menu
end

--- Start and show the menu bar item
function MenuBar.start()
  if not config.menubar then return end

  if not statusItem then
    statusItem = hs.menubar.new()
    if statusItem then
      local icon = util.createMenuBarIcon()
      statusItem:setIcon(icon)
      statusItem:setTooltip("StageLight - Ambient Focus Dimmer")
      statusItem:setMenu(buildMenu)
      log.i("StageLight menu bar item initialized")
    end
  end
end

--- Update tooltip / status if needed
function MenuBar.update()
  if statusItem then
    local state = config.enabled and string.format("StageLight: %d%%", math.floor(config.dimOpacity * 100 + 0.5)) or "StageLight: Paused"
    statusItem:setTooltip(state)
  end
end

--- Stop and remove the menu bar item
function MenuBar.stop()
  if statusItem then
    statusItem:delete()
    statusItem = nil
  end
end

return MenuBar
