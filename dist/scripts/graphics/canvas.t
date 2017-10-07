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
  self._tex = options.target or self:_create_tex(options)
  self._clear = options.clear
end

function CanvasComponent:_create_tex(options)
  if self._tex then self._tex:destroy() end
  if not (options.width and options.height) then return nil end
  local gfx = require("gfx")
  return gfx.Texture():create_blit_dest(options)
  --return gfx.RenderTarget(options.width, options.height):make_RGB8(false)
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
  local rfunc = function(task, stage, context)
    context.view:set{
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
    self._task.tex = self._tex
    self._task.func = rfunc
  else
    self._task = self:submit{func = rfunc, tex = self._tex}
  end
end

return m