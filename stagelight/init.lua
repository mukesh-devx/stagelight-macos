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
local resizeEdge = nil
local isEasyResize = false
local lastDragUpdate = 0

--- Find standard window under mouse cursor (checks focused window first for 0.01ms speed)
local function findWindowUnderPoint(pos)
  -- 1. Fast check: is it inside the currently focused window?
  local curWin = hs.window.focusedWindow()
  if curWin and curWin:isStandard() and not curWin:isFullScreen() then
    local f = curWin:frame()
    local margin = 10
    if f and pos.x >= f.x - margin and pos.x <= f.x + f.w + margin and
       pos.y >= f.y - margin and pos.y <= f.y + f.h + margin then
      return curWin, f
    end
  end

  -- 2. Check front-to-back ordered windows (for inactive window clicks)
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

--- Real-time 120Hz mouse event tracker for immediate spotlight tracking during drag/resize
local function onMouseEvent(e)
  if not config.enabled then return false end

  local eType = e:getType()

  if eType == hs.eventtap.event.types.leftMouseDown then
    local pos = hs.mouse.absolutePosition()
    local win, wf = findWindowUnderPoint(pos)

    if not win or not wf then
      isDragging = false
      dragWin = nil
      dimmer.clearAll()
      return false
    end

    local flags = e:getFlags()
    local isAlt = (flags.alt == true)
    local isTitlebar = (pos.y >= wf.y and pos.y <= wf.y + 44 and pos.x >= wf.x and pos.x <= wf.x + wf.w)

    -- Check if user is grabbing window borders for standard macOS resize
    local margin = 10
    local nearLeft = math.abs(pos.x - wf.x) <= margin
    local nearRight = math.abs(pos.x - (wf.x + wf.w)) <= margin
    local nearTop = math.abs(pos.y - wf.y) <= margin
    local nearBottom = math.abs(pos.y - (wf.y + wf.h)) <= margin
    local isBorderResize = (nearLeft or nearRight or nearTop or nearBottom) and not isTitlebar

    if isAlt or isTitlebar then
      isDragging = true
      isMove = true
      isResize = false
      isEasyResize = false
      dragStartPos = pos
      dragStartFrame = { x = wf.x, y = wf.y, w = wf.w, h = wf.h }
      dragWin = win
      lastDragUpdate = hs.timer.secondsSinceEpoch()
      -- Instantly spotlight the clicked window (active or inactive!)
      dimmer.update(win)
    elseif isBorderResize then
      isDragging = true
      isMove = false
      isResize = true
      isEasyResize = false
      resizeEdge = { left = nearLeft, right = nearRight, top = nearTop, bottom = nearBottom }
      dragStartPos = pos
      dragStartFrame = { x = wf.x, y = wf.y, w = wf.w, h = wf.h }
      dragWin = win
      lastDragUpdate = hs.timer.secondsSinceEpoch()
      dimmer.update(win)
    else
      isDragging = false
      dragWin = nil
      -- Regular click to focus window: immediately shift spotlight!
      dimmer.update(win)
    end

  elseif eType == hs.eventtap.event.types.rightMouseDown then
    local flags = e:getFlags()
    if flags.alt then
      -- EasyMove right-click resize
      local pos = hs.mouse.absolutePosition()
      local win, wf = findWindowUnderPoint(pos)
      if win and wf then
        isDragging = true
        isEasyResize = true
        isMove = false
        isResize = false
        dragWin = win
        dragStartFrame = wf
        lastDragUpdate = hs.timer.secondsSinceEpoch()
        dimmer.update(win)
      end
    end

  elseif eType == hs.eventtap.event.types.leftMouseDragged then
    if isDragging and dragWin and dragStartFrame and dragStartPos then
      local flags = e:getFlags()
      local pos = hs.mouse.absolutePosition()

      if flags.alt then
        -- EasyMove is actively moving/resizing the window: read exact live frame!
        local curF = dragWin:frame()
        if curF then
          dimmer.update(dragWin, curF)
        end
      else
        -- Standard macOS title bar drag or window border resize:
        local dx = pos.x - dragStartPos.x
        local dy = pos.y - dragStartPos.y

        if isMove then
          local liveFrame = {
            x = dragStartFrame.x + dx,
            y = dragStartFrame.y + dy,
            w = dragStartFrame.w,
            h = dragStartFrame.h,
          }
          dimmer.update(dragWin, liveFrame)
        elseif isResize and resizeEdge then
          local f = dragStartFrame
          local x, y, w, h = f.x, f.y, f.w, f.h
          if resizeEdge.right then w = math.max(160, f.w + dx) end
          if resizeEdge.bottom then h = math.max(100, f.h + dy) end
          if resizeEdge.left then
            local newW = math.max(160, f.w - dx)
            x = f.x + (f.w - newW)
            w = newW
          end
          if resizeEdge.top then
            local newH = math.max(100, f.h - dy)
            y = f.y + (f.h - newH)
            h = newH
          end
          dimmer.update(dragWin, { x = x, y = y, w = w, h = h })
        end
      end
    end

  elseif eType == hs.eventtap.event.types.rightMouseDragged then
    if isDragging and isEasyResize and dragWin then
      local curFrame = dragWin:frame()
      if curFrame then
        dimmer.update(dragWin, curFrame)
      end
    end

  elseif eType == hs.eventtap.event.types.leftMouseUp or eType == hs.eventtap.event.types.rightMouseUp then
    if isDragging or dragWin then
      local win = dragWin
      isDragging = false
      dragWin = nil
      dragStartPos = nil
      dragStartFrame = nil
      resizeEdge = nil
      isEasyResize = false

      -- 1. Immediate synchronous frame commit (0ms lag!)
      if win then
        dimmer.update(win)
        -- 2. Fast follow-up (5ms) for FancyZones snap commit
        hs.timer.doAfter(0.005, function()
          dimmer.update(win or hs.window.focusedWindow())
        end)
      end
    end
  end

  return false
end

--- Handle window move from keyboard or external window managers (Rectangle, Raycast, FancyZones)
local function handleWindowMoved(win)
  if not config.enabled then return end
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
