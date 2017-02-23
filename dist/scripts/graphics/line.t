-- line.t
--
-- a shader-based projected line

local class = require("class")
local math = require("math")
local Matrix4 = math.Matrix4
local Quaternion = math.Quaternion
local Vector = math.Vector
local gfx = require("gfx")
local pipeline = require("graphics/pipeline.t")

local m = {}

local LineShaderComponent = pipeline.DrawableComponent:extend("LineShaderComponent")
m.LineShaderComponent = LineShaderComponent

local internals = {}
struct internals.VertexType {
  position: float[3];
  normal: float[3];
  color0: float[4];
}

local terra declare_line_vertex(v_decl: &bgfx.vertex_decl_t)
  bgfx.vertex_decl_begin(v_decl, bgfx.get_renderer_type())
  bgfx.vertex_decl_add(v_decl, bgfx.ATTRIB_POSITION, 3,
                       bgfx.ATTRIB_TYPE_FLOAT, false, false)
  bgfx.vertex_decl_add(v_decl, bgfx.ATTRIB_NORMAL, 3,
                       bgfx.ATTRIB_TYPE_FLOAT, false, false)
  bgfx.vertex_decl_add(v_decl, bgfx.ATTRIB_COLOR0, 4,
                       bgfx.ATTRIB_TYPE_FLOAT, false, false)
  bgfx.vertex_decl_end(v_decl)
end

local function get_vertex_info()
  if internals.vert_info == nil then
    local vspec = terralib.new(bgfx.vertex_decl_t)
    declare_line_vertex(vspec)
    internals.vert_info = {ttype = internals.VertexType,
                           vdecl = vspec,
                           attributes = {position=3, normal=3, color0=4}}
  end

  return internals.vert_info
end

function LineShaderComponent:init(options)
  local opts = options or {}
  self._render_ops = {}
  self.mount_name = "line_shader"

  self.maxpoints = opts.maxpoints
  if not self.maxpoints then
    truss.error("LineShaderComponent needs maxpoints!")
    return
  end
  self.dynamic = not not opts.dynamic -- coerce to boolean
  self.geo = self:_create_buffers()
  self.mat = self:_create_material(opts.state, opts.uniforms, opts.program)
end
LineShaderComponent.on_update = pipeline.DrawableComponent.draw

local function pack_v3(dest, arr)
  -- dest is a 0-indexed terra type, arr is a 1-index lua table
  dest[0] = arr[1]
  dest[1] = arr[2]
  dest[2] = arr[3]
end

local function pack_vertex(dest, cur_pt, prev_pt, next_pt, dir)
  pack_v3(dest.position, cur_pt)
  pack_v3(dest.normal, prev_pt)
  pack_v3(dest.color0, next_pt)
  dest.color0[3] = dir
end

function LineShaderComponent:_append_segment(segpoints, vertidx, idxidx)
  local npts = #segpoints
  local nlinesegs = npts - 1
  local startvert = vertidx

  -- emit two vertices per point
  local vbuf = self.geo.verts
  for i = 1,npts do
    local curpoint = segpoints[i]
    -- shader detects line start if prevpoint==curpoint
    --                line end   if nextpoint==curpoint
    local prevpoint = segpoints[i-1] or curpoint
    local nextpoint = segpoints[i+1] or curpoint

    pack_vertex(vbuf[vertidx]  , curpoint, prevpoint, nextpoint,  1.0)
    pack_vertex(vbuf[vertidx+1], curpoint, prevpoint, nextpoint, -1.0)

    vertidx = vertidx + 2
  end

  -- emit two faces (six indices) per segment
  local ibuf = self.geo.indices
  for i = 1,nlinesegs do
    ibuf[idxidx+0] = startvert + 0
    ibuf[idxidx+1] = startvert + 1
    ibuf[idxidx+2] = startvert + 2
    ibuf[idxidx+3] = startvert + 2
    ibuf[idxidx+4] = startvert + 1
    ibuf[idxidx+5] = startvert + 3
    idxidx = idxidx + 6
    startvert = startvert + 2
  end

  return vertidx, idxidx
end

function LineShaderComponent:_create_buffers()
  local vinfo = get_vertex_info()
  local geo
  if self.dynamic then
    geo = gfx.DynamicGeometry()
  else
    geo = gfx.StaticGeometry()
  end
  geo:allocate(self.maxpoints * 2, self.maxpoints * 6, vinfo)
  return geo
end

local line_uniforms = nil
function LineShaderComponent:_create_material(state, uniforms, pgm)
  if line_uniforms == nil then
    line_uniforms = gfx.UniformSet()
    line_uniforms:add(gfx.VecUniform("u_color"))
    line_uniforms:add(gfx.VecUniform("u_thickness"))
  end

  local mat = {
    state = state or gfx.create_state(),
    uniforms = uniforms or line_uniforms:clone(),
    program = pgm or gfx.load_program("vs_line", "fs_line")
  }

  return mat
end

-- Update the line buffers: for a static line (dynamic == false)
-- this will only work once
function LineShaderComponent:set_points(lines)
  -- try to determine whether somebody has passed in a single line
  -- rather than a list of lines
  if type(lines[1][1]) == "number" then
    log.warn("Warning: Line:updateBuffers expects a list of lines!")
    log.warn("Warning: Please pass a single line as {line}")
    lines = {lines}
  end

  -- update data
  local npts = 0
  local vertidx, idxidx = 0, 0
  local nlines = #lines
  for i = 1,nlines do
    local newpoints = #(lines[i])
    if npts + newpoints > self.maxpoints then
      log.error("Exceeded max points! [" .. (npts+newpoints) .. "/"
                 .. self.maxpoints .. "]")
      break
    end
    vertidx, idxidx = self:_append_segment(lines[i], vertidx, idxidx)
  end

  self.geo:update()
end

return m
