-- gfx/imgui.t
--
-- imgui

local modutils = require("core/module.t")
local class = require("class")
local m = {}

local imgui_c_raw = terralib.includec("bgfx/cimgui.h")

local ig_c = {}
local ig_constants = {}
modutils.reexport_without_prefix(imgui_c_raw, "", ig_c)
modutils.reexport_without_prefix(imgui_c_raw, "ig", ig_c)
m.C = ig_c
m.C_raw = imgui_c_raw

function m.init(width, height, fontsize, viewid)
  m._width = assert(width)
  m._height = assert(height)
  m._viewid = viewid or 255
  m._fontsize = fontsize or 18.0
  log.info("Initting imgui????")
  ig_c.BGFXCreate(m._fontsize)
  log.info("Done initting????")
  m._demo_window_open = terralib.new(bool[1])
  m._demo_window_open[0] = true
end

function m.begin_frame()
  log.info("Beginning imgui frame????")
  ig_c.BGFXBeginFrame(m._width, m._height, m._viewid)
  log.info("Done beginning frame????")
end

function m.end_frame()
  log.info("Ending imgui frame????")
  ig_c.BGFXEndFrame()
  log.info("Done ending imgui frame????")
end

function m.show_demo_window()
  log.info("Showing demo window????")
  ig_c.ShowDemoWindow(m._demo_window_open)
  log.info("Done showing demo window????")
end

return m