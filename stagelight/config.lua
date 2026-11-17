--- Configuration and settings persistence for StageLight.

local Config = {
  enabled = true,

  -- Dimming appearance
  dimOpacity = 0.42,          -- 0.10 to 0.90 (default balanced 42%)
  dimColor = "#000000",       -- Deep black background veil
  dimMenuBarAndDock = false,  -- Keep menu bar and dock completely clear & bright
  dimInactiveScreens = true,  -- Cover non-active monitors with full dim veil

  -- Active window spotlight glow
  glowBorder = true,          -- Apple-style glowing border around active window
  borderWidth = 2.0,          -- Border thickness (pts)
  borderRadius = 10,          -- Corner curve matching macOS windows (pts)
  accentColorName = "blue",   -- Default accent color
  accentColors = {
    blue = { hex = "#0A84FF", name = "Electric Blue" },
    purple = { hex = "#BF5AF2", name = "Lavender Purple" },
    green = { hex = "#30D158", name = "Cyber Green" },
    orange = { hex = "#FF9F0A", name = "Sunset Orange" },
    slate = { hex = "#8E8E93", name = "Minimal Slate" },
  },

  -- Presets
  presets = {
    { id = "soft", name = "Soft", opacity = 0.25 },
    { id = "balanced", name = "Balanced", opacity = 0.42 },
    { id = "cinema", name = "Cinema", opacity = 0.65 },
    { id = "studio", name = "Studio Dark", opacity = 0.80 },
  },

  -- Behavior
  autoHideFullScreen = true,  -- Smoothly hide when active window is native fullscreen
  showHUD = true,             -- Show Apple bezel HUD on hotkey / preset toggle
  menubar = true,             -- Show status item in macOS menu bar

  -- Hotkeys (⌥D = toggle, ⌥] = dim more, ⌥[ = dim less, ⌥\ = cycle accent)
  hotkeys = {
    toggle = { { "alt" }, "d" },
    increaseOpacity = { { "alt" }, "]" },
    decreaseOpacity = { { "alt" }, "[" },
    cycleAccent = { { "alt" }, "\\" },
  },

  -- Window move tracking throttle (in seconds, 0.016 = 60fps)
  moveThrottle = 0.016,
}

local SETTINGS_KEY = "stagelight_preferences"

--- Load saved preferences from hs.settings
function Config.load()
  local saved = hs.settings.get(SETTINGS_KEY)
  if type(saved) == "table" then
    if saved.enabled ~= nil then Config.enabled = saved.enabled end
    if saved.dimOpacity ~= nil then Config.dimOpacity = saved.dimOpacity end
    if saved.dimMenuBarAndDock ~= nil then Config.dimMenuBarAndDock = saved.dimMenuBarAndDock end
    if saved.dimInactiveScreens ~= nil then Config.dimInactiveScreens = saved.dimInactiveScreens end
    if saved.glowBorder ~= nil then Config.glowBorder = saved.glowBorder end
    if saved.accentColorName ~= nil and Config.accentColors[saved.accentColorName] then
      Config.accentColorName = saved.accentColorName
    end
    if saved.autoHideFullScreen ~= nil then Config.autoHideFullScreen = saved.autoHideFullScreen end
    if saved.showHUD ~= nil then Config.showHUD = saved.showHUD end
  end
  return Config
end

--- Save current preferences to hs.settings
function Config.save()
  hs.settings.set(SETTINGS_KEY, {
    enabled = Config.enabled,
    dimOpacity = Config.dimOpacity,
    dimMenuBarAndDock = Config.dimMenuBarAndDock,
    dimInactiveScreens = Config.dimInactiveScreens,
    glowBorder = Config.glowBorder,
    accentColorName = Config.accentColorName,
    autoHideFullScreen = Config.autoHideFullScreen,
    showHUD = Config.showHUD,
  })
end

return Config
