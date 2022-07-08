-- tmath.t
-- terra math
local C = require("native/clib.t").math
local m = {}

local vectors = {}

-------------------------------------------------------------------------------
-- Represent an n-dimensional column vector.
--
-- This creates an opaque type representing the vector and caches it in a lua
-- table for subsequent uses.
local function Vector(elementType, n)
  -- Reuse existing types if they have already been declared.
  if vectors[n] then
    return vectors[n]
  end

  local V = struct {
    data: elementType[n]
  }
  local VP = &vector(elementType, n)

  -- Meta-program a setter by creating a list of setter operators for each
  -- element of the matrix.
  local statements = terralib.newlist()
  local s = symbol(&V)
  local args = {}

  for i = 1, n do
    args[i] = symbol(elementType)
    local statement = quote
      [s].data[i-1] = [args[i]]
    end
    statements:insert(statement)
  end

  local terra set([s], [args])
    [statements]
  end

  ----------
  -- Copy --
  ----------
  local terra copy_V(self : &V, rhs : &V)
    self.data = rhs.data
  end

  --------------
  -- Addition --
  --------------
  local terra add_VV(self : &V, rhs : &V) : V
    var v : V
    @VP(&v.data) = @VP(&self.data) + @VP(&rhs.data)
    return v
  end

  local terra add_VS(self : &V, rhs : elementType) : V
    var v : V
    for i = 0, n do
      v.data[i] = self.data[i] + rhs
    end
    return v
  end

  -----------------
  -- Subtraction --
  -----------------
  local terra sub_VV(self : &V, rhs : &V) : V
    var v : V
    @VP(&v.data) = @VP(&self.data) - @VP(&rhs.data)
    return v
  end

  local terra sub_VS(self : &V, rhs : elementType) : V
    var v : V
    for i = 0, n do
      v.data[i] = self.data[i] - rhs
    end
    return v
  end

  --------------------
  -- Multiplication --
  --------------------
  local terra mul_VV(self : &V, rhs : &V) : V
    var v : V
    @VP(&v.data) = @VP(&self.data) * @VP(&rhs.data);
    return v
  end

  local terra mul_VS(self : &V, rhs : elementType) : V
    var v : V
    for i = 0, n do
      v.data[i] = self.data[i] * rhs
    end
    return v
  end

  local terra div_VV(self : &V, rhs : &V) : V
    var v : V
    @VP(&v.data) = @VP(&self.data) / @VP(&rhs.data);
    return v
  end

  local terra div_VS(self : &V, rhs : elementType) : V
    var v : V
    for i = 0, n do
      v.data[i] = self.data[i] / rhs
    end
    return v
  end

  -----------------------
  -- Vector Properties --
  -----------------------
  local terra dot(self : &V, rhs : &V) : elementType
    var v : elementType = 0
    for i = 0, n do
      v = v + self.data[i] * rhs.data[i]
    end
    return v
  end

  if n == 3 then
    V.methods.cross = terra(self : &V, rhs : &V) : V
      var v : V
      v.data[0] = self.data[1] * rhs.data[2] - self.data[2] * rhs.data[1]
      v.data[1] = self.data[2] * rhs.data[0] - self.data[0] * rhs.data[2]
      v.data[2] = self.data[0] * rhs.data[1] - self.data[1] * rhs.data[0]
      return v
    end
  end

  local terra size(self : &V) : uint32
    return n
  end

  -- Get correct version of C math functions based on element type.
  local pow, sqrt
  if elementType == float then
    pow = C.powf
    sqrt = C.sqrtf
  else
    pow = C.pow
    sqrt = C.sqrt
  end

  -- Default norm is specialized as L2.
  local terra norm2sq(self : &V) : elementType
    var result : elementType = 0
    for i = 0, n do
      result = result + self.data[i] * self.data[i]
    end
    return result
  end

  local terra norm2(self : &V) : elementType
    return sqrt(norm2sq(self))
  end

  local terra norm(self : &V, degree : elementType) : elementType
    if degree == 2 then return norm2(self) end

    var result : elementType = 0
    for i = 0, n do
      result = result + pow(self.data[i], degree)
    end
    return pow(result, 1.0 / degree)
  end

  local terra zeros() : V
    var v : V
    for i = 0, n do
      v.data[i] = 0
    end
    return v
  end

  -- Return a unit-length scaled version of this vector
  local terra normalize(self : &V) : V
    var len = norm2(self)
    if len > 0.0 then
      return div_VS(self, norm2(self))
    else
      return zeros()
    end
  end

  ------------------
  -- Method Setup --
  ------------------
  V.metamethods.__add = terralib.overloadedfunction("add", {add_VV, add_VS})
  V.methods.add = add_VS
  V.metamethods.__sub = terralib.overloadedfunction("sub", {sub_VV, sub_VS})
  V.methods.sub = sub_VS
  V.metamethods.__mul = terralib.overloadedfunction("mul", {mul_VV, mul_VS})
  V.methods.mul = mul_VS
  V.metamethods.__div = terralib.overloadedfunction("div", {div_VV, div_VS})
  V.methods.div = div_VS
  V.methods.norm = terralib.overloadedfunction("norm", {norm2, norm})
  V.methods.normsq = norm2sq
  V.methods.length = norm2
  V.methods.length_squared = norm2sq
  V.methods.dot = dot
  V.methods.size = size
  V.methods.normalize = normalize
  V.methods.zeros = zeros
  V.methods.set = set

  V:complete()
  vectors[n] = V
  return V
end
m.NVector = Vector
m.Vec3f = Vector(float, 3)

return m