-- grid.t
--
-- creates a basic grid

local line = require("graphics/line.t")
local m = {}

local function add_line_circle(dest, rad)
  -- create a circle
  local circlepoints = {}
  local npts = 60
  local dtheta = math.pi * 2.0 / (npts - 1)
  for i = 1,npts do
      local x = rad * math.cos(i * dtheta)
      local y = rad * math.sin(i * dtheta)
      local z = 0.0
      circlepoints[i] = {x, y, z}
  end
  table.insert(dest, circlepoints)
  return npts
end

local function add_segmented_line(dest, v0, v1, nsteps)
  local dx = (v1[1] - v0[1]) / (nsteps - 1)
  local dy = (v1[2] - v0[2]) / (nsteps - 1)
  local dz = (v1[3] - v0[3]) / (nsteps - 1)

  local curline = {}
  local x, y, z = v0[1], v0[2], v0[3]
  for i = 0,(nsteps-1) do
      table.insert(curline, {x, y, z})
      x, y, z = x + dx, y + dy, z + dz
  end
  table.insert(dest, curline)
  return #curline
end

function m.grid_segments(options)
  options = options or {}

  local dx = options.spacing or 0.5
  local nx = options.numlines or 20
  local dy = dx
  local ny = nx

  local r0 = 0.0
  local dr = options.rspacing or dx
  local nr = options.numcircles or math.ceil(nx / 2)

  local x0 = -0.5 * nx * dx
  local y0 = -0.5 * ny * dy

  local x1 = x0 + nx*dx
  local y1 = y0 + ny*dy

  local lines = {}
  local npts = 0

  for ix = 0,nx do
    local x = x0 + ix*dx
    local v0 = {x, y0, 0}
    local v1 = {x, y1, 0}
    npts = npts + add_segmented_line(lines, v0, v1, 30)
  end

  for iy = 0,ny do
    local y = y0 + iy*dy
    local v0 = {x0, y, 0}
    local v1 = {x1, y, 0}
    npts = npts + add_segmented_line(lines, v0, v1, 30)
  end

  for ir = 1,nr do
    npts = npts + add_line_circle(lines, r0 + ir*dr)
  end

  return lines, npts
end

function m.Grid(_ecs, options)
  local pts, npts = m.grid_segments(options)
  local entity = require("ecs/entity.t")
  local line_comp = line.LineRenderComponent({maxpoints = npts})
  line_comp:set_points(pts)
  if options.color then line_comp.mat.uniforms.u_color:set(options.color) end
  if options.thickness then line_comp.mat.uniforms.u_thickness:set({options.thickness}) end
  return entity.Entity3d(_ecs, options.name or "grid", line_comp)
end

return m
