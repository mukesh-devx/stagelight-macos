--- Multi-display Dimmer Canvas Manager for StageLight.
--- Renders a 4-rectangle non-overlapping hole punch around the focused window
--- with an Apple-style glowing accent border. 100% click-through to background apps.

local config = require("stagelight.config")
local util = require("stagelight.util")
local log = require("stagelight.log")

local Dimmer = {}
Dimmer.__index = Dimmer

local canvases = {}       -- [screenID] = { canvas = hs.canvas, frame = rect }
local screenWatcher = nil
local lastFocusedWinId = nil
local lastWinFrame = nil

--- Calculate screen frame based on user preferences (menu bar & dock exclusion)
local function getScreenTargetFrame(screen)
  if config.dimMenuBarAndDock then
    return screen:fullFrame()
  else
    return screen:frame()
  end
end

--- Get or create canvas for a given screen
local function getCanvasForScreen(screen)
  local sid = screen:id()
  local targetFrame = getScreenTargetFrame(screen)
  local entry = canvases[sid]

  if entry and entry.canvas then
    -- Verify frame hasn't changed (e.g. dock toggled or resolution changed)
    local cur = entry.frame
    if cur.x == targetFrame.x and cur.y == targetFrame.y and cur.w == targetFrame.w and cur.h == targetFrame.h then
      return entry.canvas
    end
    -- Frame changed, recreate
    entry.canvas:delete()
    canvases[sid] = nil
  end

  local c = hs.canvas.new(targetFrame)
  c:level(hs.canvas.windowLevels.overlay)
  c:behavior({ "canJoinAllSpaces", "fullScreenAuxiliary" })
  c:clickActivating(false)
  c:canvasMouseEvents(false)
  c:show()

  canvases[sid] = {
    canvas = c,
    frame = targetFrame,
  }
  return c
end

--- Clean up canvases for disconnected screens
local function cleanupStaleScreens()
  local activeScreenIds = {}
  for _, s in ipairs(hs.screen.allScreens()) do
    activeScreenIds[s:id()] = true
  end

  for sid, entry in pairs(canvases) do
    if not activeScreenIds[sid] then
      if entry.canvas then
        entry.canvas:delete()
      end
      canvases[sid] = nil
    end
  end
end

--- Clear all dimming rectangles across all screens (reveal desktop)
function Dimmer.clearAll()
  for _, entry in pairs(canvases) do
    if entry.canvas then
      entry.canvas:replaceElements()
    end
  end
  lastFocusedWinId = nil
  lastWinFrame = nil
end

--- Update the spotlight cutout around the focused window
function Dimmer.update(win)
  if not config.enabled then
    Dimmer.clearAll()
    return
  end

  win = win or hs.window.focusedWindow()

  -- If no window or non-standard window (e.g. desktop click, menubar, daemon)
  if not win or not win:isStandard() then
    Dimmer.clearAll()
    return
  end

  -- Auto-hide in native macOS fullscreen
  if config.autoHideFullScreen and win:isFullScreen() then
    Dimmer.clearAll()
    return
  end

  local wf = win:frame()
  if not wf or wf.w <= 0 or wf.h <= 0 then
    Dimmer.clearAll()
    return
  end

  local winId = win:id()
  lastFocusedWinId = winId
  lastWinFrame = wf

  cleanupStaleScreens()

  local dimColor = util.parseHexColor(config.dimColor, config.dimOpacity)
  local accentCfg = config.accentColors[config.accentColorName] or config.accentColors.blue
  local accentColor = util.parseHexColor(accentCfg.hex, 0.90)
  local haloColor = util.parseHexColor(accentCfg.hex, 0.22)

  local allScreens = hs.screen.allScreens()
  for _, screen in ipairs(allScreens) do
    local c = getCanvasForScreen(screen)
    local sf = getScreenTargetFrame(screen)

    -- Intersection between window frame and this screen's frame
    local x1 = math.max(wf.x, sf.x)
    local y1 = math.max(wf.y, sf.y)
    local x2 = math.min(wf.x + wf.w, sf.x + sf.w)
    local y2 = math.min(wf.y + wf.h, sf.y + sf.h)

    local elements = {}

    if x1 < x2 and y1 < y2 then
      -- Window intersects this screen! Cut out the active window area
      local cutX = x1 - sf.x
      local cutY = y1 - sf.y
      local cutW = x2 - x1
      local cutH = y2 - y1

      -- 1. Top dimming rectangle
      if cutY > 0 then
        table.insert(elements, {
          type = "rectangle",
          action = "fill",
          fillColor = dimColor,
          frame = { x = 0, y = 0, w = sf.w, h = cutY },
        })
      end

      -- 2. Bottom dimming rectangle
      local bottomH = sf.h - (cutY + cutH)
      if bottomH > 0 then
        table.insert(elements, {
          type = "rectangle",
          action = "fill",
          fillColor = dimColor,
          frame = { x = 0, y = cutY + cutH, w = sf.w, h = bottomH },
        })
      end

      -- 3. Left dimming rectangle
      if cutX > 0 then
        table.insert(elements, {
          type = "rectangle",
          action = "fill",
          fillColor = dimColor,
          frame = { x = 0, y = cutY, w = cutX, h = cutH },
        })
      end

      -- 4. Right dimming rectangle
      local rightW = sf.w - (cutX + cutW)
      if rightW > 0 then
        table.insert(elements, {
          type = "rectangle",
          action = "fill",
          fillColor = dimColor,
          frame = { x = cutX + cutW, y = cutY, w = rightW, h = cutH },
        })
      end

      -- 5. Apple-style Glowing Accent Border
      if config.glowBorder then
        -- Outer soft halo
        table.insert(elements, {
          type = "rectangle",
          action = "stroke",
          strokeColor = haloColor,
          strokeWidth = 3,
          roundedRectRadii = {
            xRadius = config.borderRadius + 1,
            yRadius = config.borderRadius + 1,
          },
          frame = { x = cutX - 1, y = cutY - 1, w = cutW + 2, h = cutH + 2 },
        })
        -- Crisp inner accent border
        table.insert(elements, {
          type = "rectangle",
          action = "stroke",
          strokeColor = accentColor,
          strokeWidth = config.borderWidth,
          roundedRectRadii = {
            xRadius = config.borderRadius,
            yRadius = config.borderRadius,
          },
          frame = { x = cutX, y = cutY, w = cutW, h = cutH },
        })
      end
    else
      -- Window does NOT intersect this screen
      if config.dimInactiveScreens then
        table.insert(elements, {
          type = "rectangle",
          action = "fill",
          fillColor = dimColor,
          frame = { x = 0, y = 0, w = sf.w, h = sf.h },
        })
      end
    end

    if #elements == 0 then
      c:replaceElements()
    else
      c:replaceElements(elements)
    end
    if not c:isShowing() then
      c:show()
    end
  end
end

--- Force rebuild all canvases (e.g. after display topology changes or settings changes)
function Dimmer.rebuild()
  for sid, entry in pairs(canvases) do
    if entry.canvas then
      entry.canvas:delete()
    end
  end
  canvases = {}
  Dimmer.update()
end

--- Start display watcher and initialize
function Dimmer.start()
  if not screenWatcher then
    screenWatcher = hs.screen.watcher.new(function()
      log.i("Display configuration changed, rebuilding StageLight canvases")
      Dimmer.rebuild()
    end)
    screenWatcher:start()
  end
  Dimmer.update()
end

--- Stop and clean up all canvases
function Dimmer.stop()
  if screenWatcher then
    screenWatcher:stop()
    screenWatcher = nil
  end
  for sid, entry in pairs(canvases) do
    if entry.canvas then
      entry.canvas:delete()
    end
  end
  canvases = {}
  lastFocusedWinId = nil
  lastWinFrame = nil
end

return Dimmer
