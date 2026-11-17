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

--- Real-time 120Hz mouse event tracker for immediate spotlight tracking during drag/resize
local function onMouseEvent(e)
  if not config.enabled then return false end

  local eType = e:getType()

  if eType == hs.eventtap.event.types.leftMouseDown then
    local win = hs.window.focusedWindow()
    if not win or not win:isStandard() then
      isDragging = false
      return false
    end

    local wf = win:frame()
    if not wf then return false end

    local pos = hs.mouse.getAbsolutePosition()
    local flags = e:getFlags()

    local margin = 10
    local inBounds = (pos.x >= wf.x - margin and pos.x <= wf.x + wf.w + margin and
                      pos.y >= wf.y - margin and pos.y <= wf.y + wf.h + margin)
    if not inBounds then
      isDragging = false
      return false
    end

    local isAlt = (flags.alt == true)
    local isTitlebar = (pos.y >= wf.y and pos.y <= wf.y + 44 and pos.x >= wf.x and pos.x <= wf.x + wf.w)

    -- Check if user is grabbing window borders for standard macOS resize
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
    else
      isDragging = false
    end

  elseif eType == hs.eventtap.event.types.rightMouseDown then
    local flags = e:getFlags()
    if flags.alt then
      -- EasyMove right-click resize
      local win = hs.window.focusedWindow()
      if win and win:isStandard() then
        isDragging = true
        isEasyResize = true
        isMove = false
        isResize = false
        dragWin = win
        dragStartFrame = win:frame()
        lastDragUpdate = hs.timer.secondsSinceEpoch()
      end
    end

  elseif eType == hs.eventtap.event.types.leftMouseDragged then
    if isDragging and dragWin and dragStartFrame and dragStartPos then
      local now = hs.timer.secondsSinceEpoch()
      if now - lastDragUpdate >= 0.008 then -- ~120fps gate
        lastDragUpdate = now
        local pos = hs.mouse.getAbsolutePosition()
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
      local now = hs.timer.secondsSinceEpoch()
      if now - lastDragUpdate >= 0.008 then
        lastDragUpdate = now
        local curFrame = dragWin:frame()
        if curFrame then
          dimmer.update(dragWin, curFrame)
        end
      end
    end

  elseif eType == hs.eventtap.event.types.leftMouseUp or eType == hs.eventtap.event.types.rightMouseUp then
    if isDragging then
      local win = dragWin
      isDragging = false
      dragWin = nil
      dragStartPos = nil
      dragStartFrame = nil
      resizeEdge = nil
      isEasyResize = false

      -- Commit to actual final frame after macOS commits the drag
      hs.timer.doAfter(0.02, function()
        dimmer.update(win or hs.window.focusedWindow())
      end)
    end
  end

  return false
end

--- Handle window move from keyboard or external window managers (Rectangle, Raycast)
local function handleWindowMoved(win)
  if not config.enabled or isDragging then return end
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
