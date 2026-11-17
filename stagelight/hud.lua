--- Native Apple Bezel HUD notifications for StageLight.
--- Replicates macOS translucent dark capsule HUD (e.g. "Hold ⌘Q to Quit" or Volume/Brightness bezel).

local HUD = {}
HUD.__index = HUD

local activeCanvas = nil
local dismissTimer = nil

local function cleanup()
  if dismissTimer then
    dismissTimer:stop()
    dismissTimer = nil
  end
  if activeCanvas then
    activeCanvas:delete()
    activeCanvas = nil
  end
end

--- Display a simple text capsule HUD (e.g. "StageLight Enabled")
function HUD.show(text, icon, duration)
  cleanup()
  duration = duration or 0.85

  local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  if not screen then return end
  local sf = screen:frame()

  local displayText = text
  if icon and icon ~= "" then
    displayText = icon .. "   " .. text
  end

  local charCount = #displayText
  local pillW = math.max(220, math.min(charCount * 11 + 48, 440))
  local pillH = 54

  local pillX = math.floor(sf.x + (sf.w - pillW) / 2 + 0.5)
  local pillY = math.floor(sf.y + (sf.h - pillH) * 0.44 + 0.5)

  local c = hs.canvas.new({ x = pillX, y = pillY, w = pillW, h = pillH })
  c:level(hs.canvas.windowLevels.overlay)
  c:behavior({ "canJoinAllSpaces", "fullScreenAuxiliary" })

  c:replaceElements({
    -- 1. Dark frosted bezel capsule
    {
      type = "rectangle",
      action = "strokeAndFill",
      fillColor = { red = 0.10, green = 0.10, blue = 0.12, alpha = 0.92 },
      strokeColor = { red = 1.0, green = 1.0, blue = 1.0, alpha = 0.18 },
      strokeWidth = 1,
      roundedRectRadii = { xRadius = 16, yRadius = 16 },
      frame = { x = 0, y = 0, w = "100%", h = "100%" },
    },
    -- 2. Inner subtle glow rim
    {
      type = "rectangle",
      action = "stroke",
      strokeColor = { red = 1.0, green = 1.0, blue = 1.0, alpha = 0.06 },
      strokeWidth = 1,
      roundedRectRadii = { xRadius = 15, yRadius = 15 },
      frame = { x = 1, y = 1, w = pillW - 2, h = pillH - 2 },
    },
    -- 3. Centered SF Pro Bold text
    {
      type = "text",
      text = displayText,
      textFont = ".AppleSystemUIFont",
      textSize = 15,
      textColor = { white = 0.98, alpha = 1.0 },
      textAlignment = "center",
      frame = { x = 12, y = 17, w = pillW - 24, h = 24 },
    },
  })

  c:show(0.10)
  c:bringToFront(true)
  activeCanvas = c

  dismissTimer = hs.timer.doAfter(duration, function()
    if activeCanvas then
      activeCanvas:hide(0.18)
      hs.timer.doAfter(0.20, function()
        if activeCanvas then
          activeCanvas:delete()
          activeCanvas = nil
        end
      end)
    end
    dismissTimer = nil
  end)
end

--- Display an Apple-style slider progress HUD (e.g. for adjusting dimming level)
function HUD.showProgress(title, percent, icon, duration)
  cleanup()
  duration = duration or 0.80

  percent = math.max(0.0, math.min(1.0, percent))

  local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  if not screen then return end
  local sf = screen:frame()

  local pillW = 230
  local pillH = 68

  local pillX = math.floor(sf.x + (sf.w - pillW) / 2 + 0.5)
  local pillY = math.floor(sf.y + (sf.h - pillH) * 0.44 + 0.5)

  local trackW = 170
  local trackH = 6
  local trackX = math.floor((pillW - trackW) / 2 + 0.5)
  local trackY = 46

  local displayLabel = string.format("%s  %d%%", title, math.floor(percent * 100 + 0.5))
  if icon and icon ~= "" then
    displayLabel = icon .. "   " .. displayLabel
  end

  local c = hs.canvas.new({ x = pillX, y = pillY, w = pillW, h = pillH })
  c:level(hs.canvas.windowLevels.overlay)
  c:behavior({ "canJoinAllSpaces", "fullScreenAuxiliary" })

  local fillW = math.max(6, math.floor(trackW * percent + 0.5))

  c:replaceElements({
    -- 1. Dark frosted bezel capsule
    {
      type = "rectangle",
      action = "strokeAndFill",
      fillColor = { red = 0.10, green = 0.10, blue = 0.12, alpha = 0.92 },
      strokeColor = { red = 1.0, green = 1.0, blue = 1.0, alpha = 0.18 },
      strokeWidth = 1,
      roundedRectRadii = { xRadius = 16, yRadius = 16 },
      frame = { x = 0, y = 0, w = "100%", h = "100%" },
    },
    -- 2. Inner subtle glow rim
    {
      type = "rectangle",
      action = "stroke",
      strokeColor = { red = 1.0, green = 1.0, blue = 1.0, alpha = 0.06 },
      strokeWidth = 1,
      roundedRectRadii = { xRadius = 15, yRadius = 15 },
      frame = { x = 1, y = 1, w = pillW - 2, h = pillH - 2 },
    },
    -- 3. Label text
    {
      type = "text",
      text = displayLabel,
      textFont = ".AppleSystemUIFont",
      textSize = 14,
      textColor = { white = 0.98, alpha = 1.0 },
      textAlignment = "center",
      frame = { x = 10, y = 14, w = pillW - 20, h = 20 },
    },
    -- 4. Progress track groove (unfilled)
    {
      type = "rectangle",
      action = "fill",
      fillColor = { white = 0.35, alpha = 0.45 },
      roundedRectRadii = { xRadius = 3, yRadius = 3 },
      frame = { x = trackX, y = trackY, w = trackW, h = trackH },
    },
    -- 5. Progress fill (illuminated)
    {
      type = "rectangle",
      action = "fill",
      fillColor = { white = 1.0, alpha = 0.95 },
      roundedRectRadii = { xRadius = 3, yRadius = 3 },
      frame = { x = trackX, y = trackY, w = fillW, h = trackH },
    },
  })

  c:show(0.08)
  c:bringToFront(true)
  activeCanvas = c

  dismissTimer = hs.timer.doAfter(duration, function()
    if activeCanvas then
      activeCanvas:hide(0.18)
      hs.timer.doAfter(0.20, function()
        if activeCanvas then
          activeCanvas:delete()
          activeCanvas = nil
        end
      end)
    end
    dismissTimer = nil
  end)
end

return HUD
