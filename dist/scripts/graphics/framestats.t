-- graphics/framestats.t
--
-- frame timer stuff

local class = require("class")
local m = {}

local DebugTextStats = class("DebugTextStats")
m.DebugTextStats = DebugTextStats

function DebugTextStats:init()
  self.mount_name = "DebugTextStats"
  self.update_priority = 0 -- doesn't really matter
  self.start_time = truss.tic()
end

function DebugTextStats:find_evt(name, info)
  for _, evt in ipairs(self.ecs.timings) do
    if evt.name == name and (info == nil or info == evt.info) then
      return evt
    end
  end
  return {name = "none", info = "none", dt = 0.0, cdt = 0.0}
end

function DebugTextStats:update_begin()
  -- Use debug font to print timing information
  local scripttime = self:find_evt("update").cdt * 1000.0
  local frametime = self:find_evt("frame_end").cdt * 1000.0

  local st = string.format("ecs time: %.2f ms", scripttime)
  local ft = string.format("frame time: %.2f ms", frametime)

  bgfx.dbg_text_clear(0, false)
  bgfx.dbg_text_printf(0, 2, 0x6f, ft)
  bgfx.dbg_text_printf(0, 3, 0x6f, st)
end

return m
