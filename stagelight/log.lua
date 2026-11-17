--- Formatted logger for StageLight.

local logger = hs.logger.new("StageLight", "info")

local M = {}

function M.setLevel(level)
  logger.setLogLevel(level or "info")
end

function M.d(...) logger.d(...) end
function M.i(...) logger.i(...) end
function M.w(...) logger.w(...) end
function M.e(...) logger.e(...) end

return M
