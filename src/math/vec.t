-- vec.t
--
-- vec4 math (incomplete)

local m = {}

local class = require("class")
local mathtypes = require("math/types.t")
local vec4_  = mathtypes.vec4_
local vec4d_ = mathtypes.vec4d_ 

local Vector = class("Vector")

function Vector:init(x, y, z, w)
  self.elem = terralib.new(vec4_)
  self:set(x, y, z, w)
end

function Vector:__tostring()
  local e = self.elem
  return ("Vector {%.2f, %.2f, %.2f, %.2f}"):format(e.x, e.y, e.z, e.w)
end

function Vector:set(x, y, z, w)
  local e = self.elem
  e.x = x or 0.0
  e.y = y or 0.0
  e.z = z or 0.0
  e.w = w or 0.0
  return self
end

function Vector:identity()
  self:set(0,0,0,1)
  return self
end

function Vector:zero()
  self:set(0,0,0,0)
  return self
end

-- local terra copyvec(src: &vec4_, dest: &vec4_)
--   @dest = @src
-- end

function Vector:copy(rhs)
  --copyvec(rhs.elem, self.elem)
  local e_d, e_s = self.elem, rhs.elem
  e_d.x = e_s.x
  e_d.y = e_s.y
  e_d.z = e_s.z
  e_d.w = e_s.w
  return self
end

function Vector:clone()
  return Vector(self:components())
end

function Vector:from_array(arr)
  self:set(arr[1], arr[2], arr[3], arr[4])
  return self
end

-- from a zero-indexed cdata array
function Vector:from_carray(arr, count)
  local ELEM_ORDER = {"x", "y", "z", "w"}
  for i = 1, count do
    self.elem[ELEM_ORDER[i]] = arr[i-1]
  end
  return self
end

function Vector:to_array(arr)
  local e = self.elem
  return {e.x, e.y, e.z, e.w}
end

function Vector:from_dict(d)
  self:set(d.x, d.y, d.z, d.w)
  return self
end

function Vector:to_dict()
  local e = self.elem
  return {x = e.x, y = e.y, z = e.z, w = e.w}
end

-- Three element version if you need a dict with exactly x,y,z and nothing else
function Vector:to_dict3()
  local e = self.elem
  return {x = e.x, y = e.y, z = e.z}
end

-- basically unpack(q:toArray())
function Vector:components()
  local e = self.elem
  return e.x, e.y, e.z, e.w
end

function Vector:length()
  local e = self.elem
  local x,y,z,w = e.x, e.y, e.z, e.w
  return math.sqrt( x*x + y*y + z*z + w*w )
end

-- length of just first three components; NOT length^3
function Vector:length3()
  local e = self.elem
  local x, y, z = e.x, e.y, e.z
  return math.sqrt( x*x + y*y + z*z )
end

function Vector:distance_to(rhs)
  local e1, e2 = self.elem, rhs.elem
  local dx, dy, dz, dw = e1.x - e2.x, e1.y - e2.y, e1.z - e2.z, e1.w - e2.w
  return math.sqrt( dx*dx + dy*dy + dz*dz + dw*dw )
end

function Vector:distance3_to(rhs)
  local e1, e2 = self.elem, rhs.elem
  local dx, dy, dz = e1.x - e2.x, e1.y - e2.y, e1.z - e2.z
  return math.sqrt( dx*dx + dy*dy + dz*dz )
end

function Vector:rand_uniform(minval, maxval)
  local d = maxval - minval
  local e = self.elem
  e.x = math.random()*d + minval
  e.y = math.random()*d + minval
  e.z = math.random()*d + minval
  e.w = math.random()*d + minval
  return self
end

function Vector:normalize()
  local length = self:length()
  local e = self.elem
  if length == 0.0 then
    e.x = 0.0
    e.y = 0.0
    e.z = 0.0
    e.w = 0.0
  else
    length = 1.0 / length
    e.x = e.x * length
    e.y = e.y * length
    e.z = e.z * length
    e.w = e.w * length
  end

  return self
end

-- normalize only the first 3 dimensions, ignoring w
function Vector:normalize3()
  self.elem.w = 0
  self:normalize()
  return self
end

-- divide x,y,z by w
function Vector:divide_perspective()
  local e = self.elem
  if e.w == 0.0 then return self end
  e.x = e.x / e.w
  e.y = e.y / e.w
  e.z = e.z / e.w
  e.w = e.w / e.w
  return self
end

function Vector:multiply(s)
  -- Multiplying in lua is actually slightly faster than calling a
  -- terra function, probably due to function call overhead
  local e = self.elem
  e.x = e.x * s
  e.y = e.y * s
  e.z = e.z * s
  e.w = e.w * s
  return self
end
Vector.mul = Vector.multiply -- convenience alias

function Vector:divide(s)
  local e = self.elem
  e.x = e.x / s
  e.y = e.y / s
  e.z = e.z / s
  e.w = e.w / s
  return self
end

function Vector:__mul(rhs)
  return self:clone():multiply(rhs)
end

function Vector:__div(rhs)
  return self:clone():divide(rhs)
end

function Vector:__unm()
  return self:clone():multiply(-1)
end

function Vector:elementwise_multiply(a, b)
  local ae, be
  if b then
    ae, be = a.elem, b.elem
  else
    ae, be = self.elem, a.elem
  end
  local e = self.elem
  e.x = ae.x * be.x
  e.y = ae.y * be.y
  e.z = ae.z * be.z
  e.w = ae.w * be.w
  return self
end

function Vector:add(a, b)
  local ae, be
  if b then
    ae, be = a.elem, b.elem
  else
    ae, be = self.elem, a.elem
  end
  local e = self.elem
  e.x = ae.x + be.x
  e.y = ae.y + be.y
  e.z = ae.z + be.z
  e.w = ae.w + be.w
  return self
end

function Vector:__add(rhs)
  return Vector():add(self, rhs)
end

function Vector:sub(a, b)
  local ae, be
  if b then
    ae, be = a.elem, b.elem
  else
    ae, be = self.elem, a.elem
  end
  local e = self.elem
  e.x = ae.x - be.x
  e.y = ae.y - be.y
  e.z = ae.z - be.z
  e.w = ae.w - be.w
  return self
end

function Vector:__sub(rhs)
  return Vector():sub(self, rhs)
end

-- make this vector equal a*alpha + b*beta
-- if beta is nil, beta = 1.0 - alpha
function Vector:lincomb(a, b, alpha, beta)
  beta = beta or (1.0 - alpha)
  local ae = a.elem
  local be = b.elem
  local e = self.elem
  e.x = alpha*ae.x + beta*be.x
  e.y = alpha*ae.y + beta*be.y
  e.z = alpha*ae.z + beta*be.z
  e.w = alpha*ae.w + beta*be.w
  return self
end

function Vector:cross(a, b)
  local ae, be
  if b then
    ae, be = a.elem, b.elem
  else
    ae, be = self.elem, a.elem
  end
  local se = self.elem
  local u1,u2,u3 = ae.x, ae.y, ae.z
  local v1,v2,v3 = be.x, be.y, be.z
  se.x = u2*v3 - u3*v2
  se.y = u3*v1 - u1*v3
  se.z = u1*v2 - u2*v1
  se.w = 0.0
  return self
end

function Vector:dot(a, b)
  local ae = a.elem
  local be = (b and b.elem) or self.elem
  return ae.x * be.x + ae.y * be.y + ae.z * be.z + ae.w * be.w
end

function Vector:dot3(a, b)
  local ae = a.elem
  local be = (b and b.elem) or self.elem
  return ae.x * be.x + ae.y * be.y + ae.z * be.z
end

local VectorD = Vector:extend("VectorD")
function VectorD:init(x, y, z, w)
  self.elem = terralib.new(vec4d_)
  self:set(x, y, z, w)
end

function VectorD:clone()
  return VectorD(self:components())
end

m.Vector = Vector
return m
