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
local dragTap = nil
local isDragging = false
local dragStartPos = nil
local dragStartFrame = nil
local dragWin = nil
local isMove = false
local isResize = false
local isPotentialDrag = false
local hasLifted = false
local dragStartPos = nil
local dragWin = nil
local appWatcher = nil

--- Public hook: called when a window drag or resize begins (from EasyMove or mouse)
function StageLight.onDragStart()
  if not config.enabled then return end
  hasLifted = true
  dimmer.fadeLift(0.08)
end

--- Public hook: called when a window drag or resize ends / snaps (from EasyMove, FancyZones, or mouse)
function StageLight.onDragEnd(win, targetFrame)
  if not config.enabled then return end
  hasLifted = false
  isPotentialDrag = false
  dragWin = nil
  dragStartPos = nil

  win = win or hs.window.focusedWindow()
  if win and win:isStandard() then
    dimmer.update(win, targetFrame, true)
    dimmer.fadeBloom(0.18)
  else
    dimmer.clearAll()
  end
end

--- Fast window finder under mouse cursor
local function findWindowUnderPoint(pos)
  -- 1. Ultra-fast check: is it inside the currently focused window? (0.01ms)
  local curWin = hs.window.focusedWindow()
  if curWin and curWin:isStandard() and not curWin:isFullScreen() then
    local f = curWin:frame()
    local margin = 10
    if f and pos.x >= f.x - margin and pos.x <= f.x + f.w + margin and
       pos.y >= f.y - margin and pos.y <= f.y + f.h + margin then
      return curWin, f
    end
  end

  -- 2. Fast CoreAccessibility system hit-test (< 1ms direct hit)
  local okEl, el = pcall(hs.axuielement.systemElementAtPosition, pos)
  if okEl and el then
    local okWin, winEl = pcall(function() return el:attributeValue("AXWindow") or el end)
    if okWin and winEl then
      local okHS, win = pcall(function() return winEl:asHSWindow() end)
      if okHS and win and win:isStandard() and not win:isFullScreen() then
        local f = win:frame()
        if f then return win, f end
      end
    end
  end

  -- 3. Fallback check across ordered windows if AX hit-test returned a sub-control
  local allWins = hs.window.orderedWindows()
  for _, w in ipairs(allWins) do
    if w ~= curWin then
      local f = w:frame()
      local margin = 10
      if f and pos.x >= f.x - margin and pos.x <= f.x + f.w + margin and
         pos.y >= f.y - margin and pos.y <= f.y + f.h + margin then
        if w:isStandard() and not w:isFullScreen() then
          return w, f
        end
      end
    end
  end

  return nil, nil
end

--- Theatrical "Lift on Drag, Bloom on Drop" mouse event tracker
local function onMouseEvent(e)
  if not config.enabled then return false end

  local eType = e:getType()

  if eType == hs.eventtap.event.types.leftMouseDown then
    local pos = hs.mouse.absolutePosition()
    local win, wf = findWindowUnderPoint(pos)

    if not win or not wf then
      isPotentialDrag = false
      dragWin = nil
      hasLifted = false
      dimmer.clearAll()
      return false
    end

    local flags = e:getFlags()
    local isAlt = (flags.alt == true)
    local isTitlebar = (pos.y >= wf.y and pos.y <= wf.y + 85 and pos.x >= wf.x and pos.x <= wf.x + wf.w)
    local margin = 10
    local isNearBorder = (math.abs(pos.x - wf.x) <= margin or
                          math.abs(pos.x - (wf.x + wf.w)) <= margin or
                          math.abs(pos.y - wf.y) <= margin or
                          math.abs(pos.y - (wf.y + wf.h)) <= margin)

    isPotentialDrag = (isAlt or isTitlebar or isNearBorder)
    dragStartPos = pos
    dragWin = win
    hasLifted = false

    -- Instantly spotlight the clicked window (active or inactive!)
    dimmer.update(win)

  elseif eType == hs.eventtap.event.types.rightMouseDown then
    local flags = e:getFlags()
    if flags.alt then
      -- EasyMove right-click resize initiation
      local pos = hs.mouse.absolutePosition()
      local win, wf = findWindowUnderPoint(pos)
      if win and wf then
        isPotentialDrag = true
        dragWin = win
        dragStartPos = pos
        hasLifted = false
        dimmer.update(win)
      end
    end

  elseif eType == hs.eventtap.event.types.leftMouseDragged or eType == hs.eventtap.event.types.rightMouseDragged then
    if isPotentialDrag and not hasLifted and dragStartPos then
      local pos = hs.mouse.absolutePosition()
      if math.abs(pos.x - dragStartPos.x) > 3 or math.abs(pos.y - dragStartPos.y) > 3 then
        -- User has moved mouse > 3px: Window movement has begun! Lift veil cleanly!
        StageLight.onDragStart()
      end
    end

  elseif eType == hs.eventtap.event.types.leftMouseUp or eType == hs.eventtap.event.types.rightMouseUp then
    if hasLifted then
      -- Drag finished! Bloom spotlight onto dropped / snapped window!
      StageLight.onDragEnd(dragWin or hs.window.focusedWindow())
    else
      -- Regular click to focus without dragging
      isPotentialDrag = false
      dragWin = nil
      dimmer.update(hs.window.focusedWindow())
    end
  end

  return false
end

--- Handle window move from keyboard or external window managers (Rectangle, Raycast, FancyZones)
local function handleWindowMoved(win)
  if not config.enabled or hasLifted then return end
  dimmer.update(win)
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

--- Public hook for external window movers (EasyMove, FancyZones)
function StageLight.onWindowMoved(win, frame)
  if not config.enabled then return end
  dimmer.update(win, frame)
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

  -- Application watcher for instant 0ms focus switching on app activation / Cmd+Tab / Dock click
  if not appWatcher then
    appWatcher = hs.application.watcher.new(function(appName, eventType, app)
      if not config.enabled then return end
      if eventType == hs.application.watcher.activated then
        local win = app and (app:mainWindow() or app:focusedWindow()) or hs.window.focusedWindow()
        if win and win:isStandard() then
          dimmer.update(win)
        end
      end
    end)
    appWatcher:start()
  end

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

  -- Start real-time drag tracking tap for 120Hz smooth spotlight following
  if not dragTap then
    dragTap = hs.eventtap.new({
      hs.eventtap.event.types.leftMouseDown,
      hs.eventtap.event.types.leftMouseDragged,
      hs.eventtap.event.types.leftMouseUp,
      hs.eventtap.event.types.rightMouseDown,
      hs.eventtap.event.types.rightMouseDragged,
      hs.eventtap.event.types.rightMouseUp,
    }, onMouseEvent)
    dragTap:start()
  end

  log.i("StageLight started successfully")
  return StageLight
end

--- Stop StageLight and release all resources
function StageLight.stop()
  if appWatcher then
    appWatcher:stop()
    appWatcher = nil
  end

  if dragTap then
    dragTap:stop()
    dragTap = nil
  end

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
