-- fullscreenstage.t
--
-- a stage for applying fullscreen shaders/postprocessing effects to
-- render targets

local gfx = require("gfx")
local math = require("math")
local pipeline = require("graphics/pipeline.t")
local m = {}

local FullscreenStage = pipeline.Stage:extend("FullscreenStage")
m.FullscreenStage = FullscreenStage
function FullscreenStage:init(options)
  self.mat = options.mat or options.material or {}
  self.num_views = 1
  self._render_ops = {}
  -- self.globals is used by the parent class Stage to set view parameters
  self.globals = options or {}
  self.globals.proj_matrix = math.Matrix4():orthographic_projection(0, 1, 0, 1, -1, 1)
  self.globals.view_matrix = math.Matrix4():identity()
  self._identity_mat = math.Matrix4():identity()
  self._quad_geo = gfx.TransientGeometry()
  if not self.mat.program then
    local vshader = options.vshader or "vs_fullscreen"
    local fshader = options.fshader or "fs_fullscreen_copy"
    log.info("PostProcessing using pgm [" .. vshader .. " | " .. fshader .. "]")
    self.mat.program = gfx.load_program(vshader, fshader)
  end
  self.mat.uniforms = self.mat.uniforms or options.uniforms
  if not self.mat.uniforms then
    self.mat.uniforms = gfx.UniformSet()
    self.mat.uniforms:add(gfx.TexUniform("s_srcTex", 0))
  end
end

function FullscreenStage:draw_fullscreen()
  gfx.set_state(self.mat.state)
  gfx.set_transform(self._identity_mat)
  self._quad_geo:quad(0.0, 0.0, 1.0, 1.0, 0.0):bind()
  self.mat.uniforms:bind()
  gfx.submit(self.view, self.mat.program)
end

function FullscreenStage:update_begin()
  self:draw_fullscreen()
end

function FullscreenStage:duplicate()
  truss.error("FullscreenStage does not implement duplicate.")
end

return m
