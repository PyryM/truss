local class = require("class")
local m = {}

local ImmediateContext = class("ImmediateContext")
function ImmediateContext:init(options)
  self._quad_geo = require("gfx").TransientGeometry()
end

function ImmediateContext:begin_view(options)
end

function ImmediateContext:_draw_quad(pos_bounds, uv_bounds, material_options)
  local material = self:_get_material(material_options)
  material:bind(self._globals)
  local x0, y0, x1, y1 = unpack(pos_bounds)
  local u0, v0, u1, v1 = unpack(uv_bounds)
  self._quad_geo:quad_uv(x0, y0, x1, y1, u0, v0, u1, v1):bind()
  gfx.submit(self._current_view_id, material._value.program)
end

function ImmediateContext:draw_quad(options)
  local pos, uv = pull_bounds(options)
  local material = pull_material_options(options)
  self:_draw_quad(pos, uv, material)
end

function ImmediateContext:_fullscreen(view_options, material_options)
  self:begin_view(view_options)
  self:_draw_quad({0, 0, 1, 1}, {0, 0, 1, 1}, material_options)
end

function ImmediateContext:fullscreen(options)
  self:_fullscreen(pull_view_options(options), pull_material_options(options))
end

function ImmediateContext:copy(options)
  local view_opts = pull_view_options(options)
  local mat_opts = pull_material_options(options)
  if not mat_opts.program then
    mat_opts.program = {"vs_fullscreen", "fs_fullscreen_copy"}
  end
  self:_fullscreen(view_opts, mat_opts)
end

function ImmediateContext:begin_nvg(options)
end

return m