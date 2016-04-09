-- math/init.t
--
-- meta-module for all the math classes 
-- (also incorporates the standard math module)

local m = {}
for k,v in pairs(math) do
    m[k] = v
end

m.Vector = require("math/vec.t").Vector
m.Matrix4 = require("math/matrix.t").Matrix4
m.Quaternion = require("math/quat.t").Quaternion

return m