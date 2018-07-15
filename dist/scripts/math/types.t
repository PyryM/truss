-- math/types.t
--
-- common terra types

local m = {}

local scalar_ = float
m.scalar_ = scalar_

struct m.vec4_ {
  x: scalar_;
  y: scalar_;
  z: scalar_;
  w: scalar_;
}

struct m.vec4d_ {
  x: double;
  y: double;
  z: double;
  w: double;
}

m.mat4_ = float[16]

return m
