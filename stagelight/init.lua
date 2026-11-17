--- StageLight - Theatrical Ambient Focus Dimmer for macOS.
--- Dims inactive windows, desktop, and other monitors with an Apple-grade dark veil,
--- keeping the active window spotlighted with a glowing accent border.
--- 100% click-through to background apps with zero latency.

local config = require("stagelight.config")
local util = require("stagelight.util")
local hud = require("stagelight.hud")
local dimmer = require("stagelight.dimmer")
local menubar = require("stagelight.menubar")
local log = require("stagelight.log")

local StageLight = {}
StageLight._VERSION = "1.0.0"

local windowFilter = nil
local hotkeys = {}
local pendingMoveTimer = nil
local lastMoveUpdate = 0

--- Throttled update during window dragging/resizing
local function handleWindowMoved(win)
  if not config.enabled then return end
  local now = hs.timer.secondsSinceEpoch()
  if now - lastMoveUpdate >= config.moveThrottle then
    lastMoveUpdate = now
    dimmer.update(win)
  else
    if not pendingMoveTimer then
      local delay = config.moveThrottle - (now - lastMoveUpdate)
      pendingMoveTimer = hs.timer.doAfter(math.max(0.005, delay), function()
        pendingMoveTimer = nil
        lastMoveUpdate = hs.timer.secondsSinceEpoch()
        dimmer.update(win or hs.window.focusedWindow())
      end)
    end
  end
end

--- Handle window focus transition
local function handleWindowFocused(win)
  if not config.enabled then return end
  dimmer.update(win)
end

--- Handle window closed / hidden / minimized
local function handleWindowClosed()
  if not config.enabled then return end
  hs.timer.doAfter(0.05, function()
    dimmer.update(hs.window.focusedWindow())
  end)
end

--- Set exact opacity value (0.10 to 0.90)
function StageLight.setOpacity(val, presetName)
  val = util.clamp(util.round(val * 100) / 100, 0.10, 0.90)
  config.dimOpacity = val
  config.save()
  menubar.update()
  dimmer.update()

  if config.showHUD then
    local label = presetName or "Dimming"
    hud.showProgress(label, config.dimOpacity, "💡")
  end
  log.i(string.format("Opacity set to %.2f (%s)", config.dimOpacity, presetName or "custom"))
end

--- Adjust opacity up or down by delta (e.g. +0.05 or -0.05)
function StageLight.adjustOpacity(delta)
  StageLight.setOpacity(config.dimOpacity + delta)
end

--- Set accent color by key (e.g. "blue", "purple", "green", "orange", "slate")
function StageLight.setAccentColor(colorKey)
  if config.accentColors[colorKey] then
    config.accentColorName = colorKey
    config.save()
    dimmer.update()
    if config.showHUD then
      hud.show(config.accentColors[colorKey].name, "🎨")
    end
  end
end

--- Cycle through available accent colors
function StageLight.cycleAccent()
  local keys = { "blue", "purple", "green", "orange", "slate" }
  local curIdx = 1
  for i, k in ipairs(keys) do
    if k == config.accentColorName then
      curIdx = i
      break
    end
  end
  local nextIdx = (curIdx % #keys) + 1
  StageLight.setAccentColor(keys[nextIdx])
end

--- Toggle StageLight on or off
function StageLight.toggle()
  config.enabled = not config.enabled
  config.save()
  menubar.update()

  if config.enabled then
    dimmer.update()
    if config.showHUD then
      hud.show("StageLight Active", "💡")
    end
    log.i("StageLight enabled")
  else
    dimmer.clearAll()
    if config.showHUD then
      hud.show("StageLight Paused", "🌙")
    end
    log.i("StageLight paused")
  end
end

--- Bind configured hotkeys
local function bindHotkeys()
  for _, hk in ipairs(hotkeys) do
    hk:delete()
  end
  hotkeys = {}

  if not config.hotkeys then return end

  -- Toggle hotkey (⌥D)
  if config.hotkeys.toggle then
    local mods, key = config.hotkeys.toggle[1], config.hotkeys.toggle[2]
    table.insert(hotkeys, hs.hotkey.bind(mods, key, function()
      StageLight.toggle()
    end))
  end

  -- Increase dimming (⌥])
  if config.hotkeys.increaseOpacity then
    local mods, key = config.hotkeys.increaseOpacity[1], config.hotkeys.increaseOpacity[2]
    table.insert(hotkeys, hs.hotkey.bind(mods, key, function()
      StageLight.adjustOpacity(0.05)
    end))
  end

  -- Decrease dimming (⌥[)
  if config.hotkeys.decreaseOpacity then
    local mods, key = config.hotkeys.decreaseOpacity[1], config.hotkeys.decreaseOpacity[2]
    table.insert(hotkeys, hs.hotkey.bind(mods, key, function()
      StageLight.adjustOpacity(-0.05)
    end))
  end

  -- Cycle accent (⌥\)
  if config.hotkeys.cycleAccent then
    local mods, key = config.hotkeys.cycleAccent[1], config.hotkeys.cycleAccent[2]
    table.insert(hotkeys, hs.hotkey.bind(mods, key, function()
      StageLight.cycleAccent()
    end))
  end
end

--- Start StageLight
function StageLight.start(userConfig)
  config.load()

  if type(userConfig) == "table" then
    for k, v in pairs(userConfig) do
      config[k] = v
    end
  end

  -- Set up menubar callbacks
  menubar.setCallbacks({
    onToggle = StageLight.toggle,
    onOpacity = StageLight.setOpacity,
    onAccent = StageLight.setAccentColor,
  })

  -- Start dimmer manager & canvases
  dimmer.start()

  -- Start menubar item
  menubar.start()

  -- Set up window filter to track focus and movement
  if not windowFilter then
    windowFilter = hs.window.filter.new()
    windowFilter:setOverrideFilter({
      visible = true,
      fullscreen = false,
      currentSpace = true,
    })

    windowFilter:subscribe(hs.window.filter.windowFocused, handleWindowFocused)
    windowFilter:subscribe(hs.window.filter.windowMoved, handleWindowMoved)
    windowFilter:subscribe(hs.window.filter.windowDestroyed, handleWindowClosed)
    windowFilter:subscribe(hs.window.filter.windowHidden, handleWindowClosed)
    windowFilter:subscribe(hs.window.filter.windowMinimized, handleWindowClosed)
  end

  -- Bind hotkeys
  bindHotkeys()

  log.i("StageLight started successfully")
  return StageLight
end

--- Stop StageLight and release all resources
function StageLight.stop()
  if windowFilter then
    windowFilter:unsubscribeAll()
    windowFilter = nil
  end

  if pendingMoveTimer then
    pendingMoveTimer:stop()
    pendingMoveTimer = nil
  end

  for _, hk in ipairs(hotkeys) do
    hk:delete()
  end
  hotkeys = {}

  menubar.stop()
  dimmer.stop()

  log.i("StageLight stopped")
end

return StageLight
