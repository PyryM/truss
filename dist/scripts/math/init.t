-- math/init.t
--
-- meta-module for all the math classes
-- (also incorporates the standard math module)

local module = require("core/module.t")

-- 'import' all the normal math functions
local m = module.reexport(math)

-- 3d math
m.Vector = require("./vec.t").Vector
m.Matrix4 = require("./matrix.t").Matrix4
m.Quaternion = require("./quat.t").Quaternion

-- Additional stuff
module.include_submodules({
  "math/bitops.t",
  "math/random.t"
}, m)

return m
