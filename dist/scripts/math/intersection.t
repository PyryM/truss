-- math/intersection.t
--
-- find intersections between things

local class = require("class")
local Matrix4 = require("math/matrix.t").Matrix4
local Vector  = require("math/vec.t").Vector

local m = {}

-- plane_frame: transform of plane in world (plane is XY, normal Z)
-- p: a position in world frame
-- v: direction/velocity in world frame
-- returns: x, y, t
-- x, y: intersection with plane in plane frame
-- t: 'time' of intersection
local temp_mat = Matrix4()
local temp_p, temp_v = Vector(), Vector()
function m.plane_intersection(plane_frame, p, v)
  local inv_frame = temp_mat:copy(plane_frame):invert()
  return m._plane_intersection(inv_frame, p, v)
end

function m._plane_intersection(inv_frame, p, v)
  local p = temp_p:copy(p)
  p.elem.w = 1 -- position like
  local v = temp_v:copy(v)
  v.elem.w = 0 -- vector like
  inv_frame:multiply(p)
  inv_frame:multiply(v)

  local t = -p.elem.z / v.elem.z
  local x = p.elem.x + (t * v.elem.x)
  local y = p.elem.y + (t * v.elem.y)

  return x, y, t
end

local PlaneIntersector = class("PlaneIntersector")
m.PlaneIntersector = PlaneIntersector

function PlaneIntersector:init(transform)
  self.mat = Matrix4():identity()
  self.inv_mat = Matrix4():identity()
  if transform then self:set_transform(transform) end
end

function PlaneIntersector:set_transform(tf)
  self.mat:copy(tf)
  self.inv_mat:invert(self.mat)
end

function PlaneIntersector:intersect(p, v)
  return m._plane_intersection(self.inv_mat, p, v)
end

function PlaneIntersector:intersect_mat(m)
  self.p = self.p or Vector()
  self.v = self.v or Vector()
  m:get_translation(self.p)
  m:get_column(3, self.v)
  return self:intersect(self.p, self.v)
end

return m