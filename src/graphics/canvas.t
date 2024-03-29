-- graphics/canvas.t
--
-- a component to simplify doing occasional 2d rendering to a texture

local class = require("class")
local ecs = require("ecs")
local tasks = require("./taskstage.t")
local m = {}

local CanvasComponent = class("CanvasComponent")
m.CanvasComponent = CanvasComponent

function CanvasComponent:init(options)
  options = options or {}
  self.mount_name = "canvas"
  self._tex = options.target or self:_create_tex(options)
  self._clear = options.clear
end

function CanvasComponent:_create_tex(options)
  if self._tex then self._tex:destroy() end
  if not (options.width and options.height) then return nil end
  local gfx = require("gfx")
  return gfx.Texture2d{
    width = options.width, height = options.height,
    format = options.format or require("gfx").TEX_BGRA8,
    flags = options.flags or {blit_dest = true},
    allocate = false
  }:commit()
end

function CanvasComponent:get_tex()
  return self._tex
end

function CanvasComponent:nvg_draw(nvg)
  nvg:BeginPath()
  nvg:Circle(nvg.width / 2, nvg.height / 2, 
             math.min(nvg.height, nvg.width) / 2)
  nvg:FillColor(nvg:RGBf(1.0, 0.0, 0.0))
  nvg:Fill()
end

function CanvasComponent:submit_draw(drawfunc)
  if not self._tex then 
    truss.error("CanvasComponent has texture.")
  end
  drawfunc = drawfunc or self.nvg_draw
  local rfunc = function(context)
    context.view:set{
      clear = self._clear or {color = 0x000000ff, depth = 1.0}
    }
    if not context.nvg then 
      context.nvg = require("gfx/nanovg.t").NVGContext(context.view, true) 
    end
    context.nvg:begin_frame(context.view)
    drawfunc(self, context.nvg)
    context.nvg:end_frame()
  end
  if self._task and not self._task.completed then
    self._task.tex = self._tex
    self._task.func = rfunc
  else
    self._task = tasks.AsyncTask{func = rfunc, tex = self._tex}
    self.ent.ecs.systems.render:queue_task(self._task)
  end
  return self._task
end

return m