-- graphics/compositestage.t
--
-- a simple stage for compositing a bunch of things together
-- (e.g., for splitscreen)

local gfx = require("gfx")
local math = require("math")
local pipeline = require("graphics/pipeline.t")
local m = {}

local CompositeStage = pipeline.Stage:extend("CompositeStage")
m.CompositeStage = CompositeStage
function CompositeStage:init(options, ops)
  self.num_views = 1
  self._render_ops = {}
  self.composite_ops = {}
  self.globals = options or {}
  self.globals.proj_matrix = math.Matrix4():orthographic_projection(0, 1, 0, 1, -1, 1)
  self.globals.view_matrix = math.Matrix4():identity()
  self._identity_mat = math.Matrix4():identity()
  self._quad_geo = gfx.TransientGeometry()
  self._sampler = gfx.TexUniform("s_srcTex", 0)
  self._program = gfx.load_program("vs_fullscreen",
                                   options.shader or "fs_fullscreen_copy")

  for k,v in pairs(ops or {}) do
    self:add_composite_operation(k, v)
  end
end

function CompositeStage:add_composite_operation(name, op)
  self.composite_ops[name] = op -- {src, x0, y0, x1, y1}
end

function CompositeStage:composite(rt, x0, y0, x1, y1)
  gfx.set_state() -- set default state
  gfx.set_transform(self._identity_mat) -- not strictly necessary
  self._quad_geo:quad(x0, y0, x1, y1, 0.0):bind()
  self._sampler:set(rt.attachments[1]):bind()
  gfx.submit(self.view, self._program)
end

function CompositeStage:update()
  for _, op in pairs(self.composite_ops) do
    self:composite(unpack(op))
  end
end

function CompositeStage:duplicate()
  truss.error("CompositeStage does not implement duplicate.")
end

return m
