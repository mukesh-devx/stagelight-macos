--- Geometry, color, icon, and math helpers for StageLight.

local M = {}

function M.clamp(val, minVal, maxVal)
  if val < minVal then return minVal end
  if val > maxVal then return maxVal end
  return val
end

function M.round(val)
  return math.floor(val + 0.5)
end

--- Parse 6-digit hex color into RGBA table for hs.canvas
function M.parseHexColor(hex, alpha)
  if not hex then
    return { red = 0.0, green = 0.0, blue = 0.0, alpha = alpha or 1.0 }
  end
  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16) or 0
  local g = tonumber(hex:sub(3, 4), 16) or 0
  local b = tonumber(hex:sub(5, 6), 16) or 0
  return { red = r / 255, green = g / 255, blue = b / 255, alpha = alpha or 1.0 }
end

--- Create an Apple-style template icon for the macOS menu bar
function M.createMenuBarIcon()
  local size = 18
  local c = hs.canvas.new({ x = 0, y = 0, w = size, h = size })
  c:replaceElements({
    -- Spotlight cone outline
    {
      type = "segments",
      action = "stroke",
      strokeColor = { white = 0.0, alpha = 1.0 },
      strokeWidth = 1.3,
      coordinates = {
        { x = 5.5, y = 4.5 },
        { x = 2.0, y = 14.5 },
        { x = 16.0, y = 14.5 },
        { x = 12.5, y = 4.5 },
        { x = 5.5, y = 4.5 },
      },
    },
    -- Spotlight lamp mount
    {
      type = "rectangle",
      action = "fill",
      fillColor = { white = 0.0, alpha = 1.0 },
      roundedRectRadii = { xRadius = 1.5, yRadius = 1.5 },
      frame = { x = 6.0, y = 2.0, w = 6.0, h = 2.5 },
    },
    -- Focal center dot
    {
      type = "circle",
      action = "fill",
      fillColor = { white = 0.0, alpha = 1.0 },
      center = { x = 9.0, y = 10.0 },
      radius = 1.8,
    },
  })
  local img = c:imageFromCanvas()
  img:template(true)
  c:delete()
  return img
end

return M
