-- line.t
--
-- a shader-based projected line

local class = require("class")
local math = require("math")
local Matrix4 = math.Matrix4
local Quaternion = math.Quaternion
local Vector = math.Vector
local gfx = require("gfx")
local render = require("./renderer.t")

local m = {}

local LineRenderComponent = render.RenderComponent:extend("LineRenderComponent")
m.LineRenderComponent = LineRenderComponent

function LineRenderComponent:init(options)
  local opts = options or {}
  self._render_ops = {}
  self.mount_name = "line"
  self.maxpoints = opts.maxpoints
  if not self.maxpoints and opts.points then
    -- infer maxpoints from length of provided point set
    self.maxpoints = 0
    for _, pts in ipairs(opts.points) do
      self.maxpoints = self.maxpoints + #pts
    end
  end
  if not self.maxpoints then
    truss.error("LineRenderComponent needs maxpoints!")
    return
  end
  self.dynamic = not not opts.dynamic -- coerce to boolean
  self.geo = self:_create_buffers()
  self.mat = self:_create_material(opts)
  self.tags = gfx.tagset{compiled = true}
  self.tags:extend(options.tags or {})
  if opts.points then self:set_points(opts.points) end
  -- Need to create drawcall last so that buffers have been created
  self.drawcall = gfx.Drawcall(self.geo, self.mat)
end

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

function LineRenderComponent:_append_segment(segpoints, vertidx, idxidx, uscale)
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
    local u = i * (uscale or (1.0 / npts))

    pack_vertex(vbuf[vertidx]  , curpoint, prevpoint, nextpoint,  u)
    pack_vertex(vbuf[vertidx+1], curpoint, prevpoint, nextpoint, -u)

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

function LineRenderComponent:_create_buffers()
  local vinfo = gfx.create_vertex_type{
      position = {ctype = float, count = 3},
      normal   = {ctype = float, count = 3},
      color0   = {ctype = float, count = 4}
  }
  local geo
  if self.dynamic then
    geo = gfx.DynamicGeometry()
  else
    geo = gfx.StaticGeometry()
  end
  geo:allocate(self.maxpoints * 2, self.maxpoints * 6, vinfo)
  return geo
end

local function line_uniforms(has_texture)
  local u = {u_baseColor = 'vec', u_thickness = 'vec'}
  if has_texture then u.s_texAlbedo = {kind = 'tex', sampler = 0} end
  return u
end

local line_materials = {}
line_materials[false] = gfx.define_base_material{
  name = "LineMaterial", uniforms = line_uniforms(false)
}
line_materials[true] = gfx.define_base_material{
  name = "LineTexMaterial", uniforms = line_uniforms(true)
}

function LineRenderComponent:_create_material(options)
  local mat = options.material
  if not mat then
    local has_texture = options.texture ~= nil
    mat = line_materials[has_texture]()

    local fsname = "fs_line"
    if has_texture then fsname = fsname .. "_textured" end
    if options.alpha_test then fsname = fsname .. "_atest" end

    if options.state then mat:set_state(options.state) end
    mat.tags = options.tags
    mat:set_program(options.program or gfx.load_program("vs_line", fsname))
  end

  mat.uniforms.u_baseColor:set(options.color or {1, 1, 0, 1})
  mat.uniforms.u_thickness:set(options.thickness or 0.1, options.u_mult or 1.0)
  if options.texture then mat.uniforms.s_texAlbedo:set(options.texture) end

  return mat
end

-- Update the line buffers: for a static line (dynamic == false)
-- this will only work once
function LineRenderComponent:set_points(lines)
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

  if self.dynamic then self.geo:update() else self.geo:commit() end
end

function m.Line(_ecs, name, options)
  local ecs = require("ecs")
  return ecs.Entity3d(_ecs, name, LineRenderComponent(options))
end

return m
