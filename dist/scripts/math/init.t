-- math/init.t
--
-- meta-module for all the math classes
-- (also incorporates the standard math module)

local m = {}

-- 'import' all the normal math functions
for k,v in pairs(math) do m[k] = v end

-- 3d math
m.Vector = require("math/vec.t").Vector
m.Matrix4 = require("math/matrix.t").Matrix4
m.Quaternion = require("math/quat.t").Quaternion

-- 64 bit bitwise operations
for k,v in pairs(require("math/bitops.t")) do m[k] = v end

return m
