-- graphics/framestats.t
--
-- frame timer stuff

local class = require("class")
local m = {}

local DebugTextStats = class("DebugTextStats")
m.DebugTextStats = DebugTextStats

function DebugTextStats:init()
  self.mount_name = "DebugTextStats"
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
  local scripttime = self:time_between("frame_start", "render_submit")
  local frametime = self:find_evt("frame_end").cdt * 1000.0

  local putime = self:time_between("frame_start", "preupdate")
  local sgtime = self:time_between("preupdate", "scenegraph")
  local uptime = self:time_between("scenegraph", "render_submit")

  local ft = string.format("frame: %5.2f ms, ecs: %5.2f ms",
                            frametime, scripttime)
  local sg = string.format("   pu: %5.2f ms,  sg: %5.2f ms, up: %5.2f ms",
                            putime, sgtime, uptime)

  bgfx.dbg_text_clear(0, false)
  bgfx.dbg_text_printf(0, 2, 0x6f, ft)
  bgfx.dbg_text_printf(0, 3, 0x6f, sg)
end

return m
