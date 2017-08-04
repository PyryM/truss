-- graphics/canvas.t
--
-- a component to simplify doing occasional 2d rendering to a texture

local class = require("class")
local ecs = require("ecs")
local tasks = require("graphics/taskstage.t")
local m = {}

local CanvasComponent = tasks.TaskSubmitter:extend("CanvasComponent")
m.CanvasComponent = CanvasComponent
function CanvasComponent:init(options)
  options = options or {}
  CanvasComponent.super.init(self, options)
  self.mount_name = "canvas"
  self._target = options.target or self:_create_target(options)
  self._clear = options.clear
end

function CanvasComponent:_create_target(options)
  if self._target then self._target:destroy() end
  if not (options.width and options.height) then return nil end
  local gfx = require("gfx")
  return gfx.RenderTarget(options.width, options.height):make_RGB8()
end

function CanvasComponent:get_target()
  return self._target
end

function CanvasComponent:nvg_draw(nvg)
  nvg:BeginPath()
  nvg:Circle(nvg.width / 2, nvg.height / 2, 
             math.min(nvg.height, nvg.width) / 2)
  nvg:FillColor(nvg:RGBf(1.0, 0.0, 0.0))
  nvg:Fill()
end

function CanvasComponent:submit_draw(drawfunc)
  if not self._target then 
    truss.error("CanvasComponent has no render target.")
  end
  drawfunc = drawfunc or self.nvg_draw
  local rfunc = function(task, stage, context)
    context.view:set{
      render_target = self._target,
      clear = self._clear or {color = 0x000000ff, depth = 1.0}
    }
    if not context.nvg then 
      context.nvg = require("addons/nanovg.t").NVGContext(context.view) 
    end
    context.nvg:begin_frame(context.view)
    drawfunc(self, context.nvg)
    context.nvg:end_frame()
  end
  if self._task and not self._task.completed then
    self._task:set_function(rfunc)
  else
    self._task = self:submit(rfunc)
  end
end

return m