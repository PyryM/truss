-- quat.t
--
-- quaternion math
-- mostly copied from threejs
--  (https://github.com/mrdoob/three.js/blob/master/src/math/Quaternion.js)

local m = {}

local class = require("class")
local matrix = require("math/matrix.t")
local vec = require("math/vec.t")

local Quaternion = vec.Vector:extend("Quaternion")

function Quaternion:__tostring()
  local e = self.elem
  return ("Quaternion {%.2f, %.2f, %.2f, %.2f}"):format(e.x, e.y, e.z, e.w)
end

function Quaternion:euler(euler, order)
  -- handle either {x=..., y=..., z=...} or {x,y,z} style
  if euler.elem then euler = euler.elem end -- handle passing in vectors
  local x = euler.x or euler[1] or 0.0
  local y = euler.y or euler[2] or 0.0
  local z = euler.z or euler[3] or 0.0

  local c1 = math.cos( x / 2 )
  local c2 = math.cos( y / 2 )
  local c3 = math.cos( z / 2 )
  local s1 = math.sin( x / 2 )
  local s2 = math.sin( y / 2 )
  local s3 = math.sin( z / 2 )
  order = order or 'XYZ'

  local e = self.elem
  if order == 'XYZ' then
    e.x = s1 * c2 * c3 + c1 * s2 * s3
    e.y = c1 * s2 * c3 - s1 * c2 * s3
    e.z = c1 * c2 * s3 + s1 * s2 * c3
    e.w = c1 * c2 * c3 - s1 * s2 * s3
  elseif order == 'YXZ' then
    e.x = s1 * c2 * c3 + c1 * s2 * s3
    e.y = c1 * s2 * c3 - s1 * c2 * s3
    e.z = c1 * c2 * s3 - s1 * s2 * c3
    e.w = c1 * c2 * c3 + s1 * s2 * s3
  elseif order == 'ZXY' then
    e.x = s1 * c2 * c3 - c1 * s2 * s3
    e.y = c1 * s2 * c3 + s1 * c2 * s3
    e.z = c1 * c2 * s3 + s1 * s2 * c3
    e.w = c1 * c2 * c3 - s1 * s2 * s3
  elseif order == 'ZYX' then
    e.x = s1 * c2 * c3 - c1 * s2 * s3
    e.y = c1 * s2 * c3 + s1 * c2 * s3
    e.z = c1 * c2 * s3 - s1 * s2 * c3
    e.w = c1 * c2 * c3 + s1 * s2 * s3
  elseif order == 'YZX' then
    e.x = s1 * c2 * c3 + c1 * s2 * s3
    e.y = c1 * s2 * c3 + s1 * c2 * s3
    e.z = c1 * c2 * s3 - s1 * s2 * c3
    e.w = c1 * c2 * c3 - s1 * s2 * s3
  elseif order == 'XZY' then
    e.x = s1 * c2 * c3 - c1 * s2 * s3
    e.y = c1 * s2 * c3 - s1 * c2 * s3
    e.z = c1 * c2 * s3 + s1 * s2 * c3
    e.w = c1 * c2 * c3 + s1 * s2 * s3
  end
  return self
end

function Quaternion:axis_angle(axis, angle)
  local half_angle = angle / 2
  local s = math.sin(half_angle)
  local e = self.elem

  e.x = axis.elem.x * s
  e.y = axis.elem.y * s
  e.z = axis.elem.z * s
  e.w = math.cos(half_angle)

  return self
end

-- makes the quaternion be the identity quaternion
function Quaternion:identity()
  local e = self.elem
  e.x, e.y, e.z, e.w = 0.0, 0.0, 0.0, 1.0
  return self
end

function Quaternion:conjugate()
  local e = self.elem
  e.x = e.x * -1
  e.y = e.y * -1
  e.z = e.z * -1

  return self
end

function Quaternion:invert()
  return self:conjugate():normalize()
end

-- Note: assumes m is a 4x4 matrix from matrix.4 (i.e., a terra float[16])
-- assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
function Quaternion:from_matrix(m)
  -- Note: we import 'late' to avoid mutual import issues
  local matrix = require("math/matrix.t")

  matrix.matrix_to_quaternion(m.data, self.elem)
  return self
end

function Quaternion:multiply( a, b )
  --from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm
  local ae, be
  if b then
    ae, be = a.elem, b.elem
  else
    ae, be = self.elem, a.elem
  end

  local qax, qay, qaz, qaw = ae.x, ae.y, ae.z, ae.w
  local qbx, qby, qbz, qbw = be.x, be.y, be.z, be.w

  local e = self.elem
  e.x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby
  e.y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz
  e.z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx
  e.w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz

  return self
end

function Quaternion:prettystr()
  local e = self.elem
  return "{" .. e.x .. ", "
         .. e.y .. ", "
         .. e.z .. ", "
         .. e.w .. "}"
end

-- 'export' classes
m.Quaternion = Quaternion
return m
