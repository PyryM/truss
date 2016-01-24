-- vec.t
--
-- vec4 math (incomplete)

local m = {}

local class = require("class")

local Vector = class("Vector")
local matrix = require("math/matrix.t")

function Vector:init(x, y, z, w)
    --self.elem = {x = 0, y = 0, z = 0, w = 0}
	self.elem = terralib.new(matrix.vec4_)
    self.e = self.elem -- alias for convenience
    self:set(x, y, z, w)
end

function Vector:set(x, y, z, w)
    local e = self.elem
    e.x = x or 0.0
    e.y = y or 0.0
    e.z = z or 0.0
    e.w = w or 1.0
    return self
end

local terra copyvec(src: &matrix.vec4_, dest: &matrix.vec4_)
    @dest = @src
end

function Vector:copy(rhs)
    copyvec(rhs.elem, self.elem)
    return self
end

function Vector:fromArray(arr)
    self:set(arr[1], arr[2], arr[3], arr[4])
    return self
end

function Vector:toArray(arr)
    local e = self.elem
    return {e.x, e.y, e.z, e.w}
end

function Vector:fromDict(d)
    self:set(d.x, d.y, d.z, d.w)
    return self
end

function Vector:toDict()
    local e = self.elem
    return {x = e.x, y = e.y, z = e.z, w = e.w}
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

function Vector:multiplyScalar(s)
    -- Multiplying in lua is actually slightly faster than calling a
    -- terra function, probably due to function call overhead
    local e = self.elem
    e.x = e.x * s
    e.y = e.y * s
    e.z = e.z * s
    e.w = e.w * s
    --multiply_vec_scalar(self.elem, s)
    return self
end

function Vector:addVecs(a, b)
    local ae = a.elem
    local be = b.elem
    local e = self.elem
    e.x = ae.x + be.x
    e.y = ae.y + be.y
    e.z = ae.z + be.z
    e.w = ae.w + be.w
    return self
end

function Vector:subVecs(a, b)
    local ae = a.elem
    local be = b.elem
    local e = self.elem
    e.x = ae.x - be.x
    e.y = ae.y - be.y
    e.z = ae.z - be.z
    e.w = ae.w - be.w
    return self
end

function Vector:crossVecs(a, b)
    local ae = a.elem
    local be = b.elem
    local se = self.elem
    local u1,u2,u3 = ae.x, ae.y, ae.z
    local v1,v2,v3 = be.x, be.y, be.z
    se.x = u2*v3 - u3*v2
    se.y = u3*v1 - u1*v3
    se.z = u1*v2 - u2*v1
    se.w = 1.0
    return self
end

function Vector:dot(a, b)
    local ae = a.elem
    local be = (b and b.elem) or self.elem
    return ae.x * be.x + ae.y * be.y + ae.z * be.z + ae.w * be.w
end

function Vector:add(rhs)
    return self:addVecs(self, rhs)
end

function Vector:sub(rhs)
    return self:subVecs(self, rhs)
end

m.Vector = Vector
m.Vec4   = Vector -- shorter alias
return m