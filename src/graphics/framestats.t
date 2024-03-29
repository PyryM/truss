-- graphics/framestats.t
--
-- frame timer stuff

local class = require("class")
local bgfx = require("gfx/bgfx.t")
local timing = require("osnative/timing.t")
local m = {}

local DebugTextStats = class("DebugTextStats")
m.DebugTextStats = DebugTextStats

function DebugTextStats:init()
  self.mount_name = "DebugTextStats"
  self.start_time = timing.tic()
end

function DebugTextStats:find_evt(name, info)
  for _, evt in ipairs(self.ecs.timings) do
    if evt.name == name and (info == nil or info == evt.info) then
      return evt
    end
  end
  return {name = "none", info = "none", dt = 0.0, cdt = 0.0}
end

function DebugTextStats:time_between(name1, name2, info1, info2)
  local e1 = self:find_evt(name1, info1)
  local e2 = self:find_evt(name2, info2)
  if e1 and e2 then
    return (e2.cdt - e1.cdt) * 1000.0
  else
    return -1.0
  end
end

function DebugTextStats:update()
  -- Use debug font to print timing information
  local scripttime = self:time_between("frame_start", "render_post")
  local frametime = self:find_evt("frame_end").cdt * 1000.0

  local utime = self:time_between("frame_start", "update")
  local rtime = self:time_between("update", "render_post")

  local ft = string.format("frame: %5.2f ms, ecs: %5.2f ms",
                            frametime, scripttime)
  local sg = string.format("   update: %5.2f ms, render: %5.2f ms",
                            utime, rtime)

  bgfx.dbg_text_clear(0, false)
  bgfx.dbg_text_printf(0, 2, 0x6f, ft)
  bgfx.dbg_text_printf(0, 3, 0x6f, sg)
end

return m
