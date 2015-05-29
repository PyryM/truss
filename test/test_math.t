-- test_math.t
--
-- tests for math function

local importpath = "../scripts/"
local emulator = require("trussemulator")

-- define truss import so that other things will work
truss_import = emulator.makeImport(importpath)

quat =   truss_import("math/quat.t")
matrix = truss_import("math/matrix.t")

m = matrix.Matrix4()
m:identity()
print(m:prettystr())

function v3(x,y,z)
	return {x = x, y = y, z = z}
end

q = quat:Quaternion()
q:fromEuler(v3(math.pi / 2.0, 2.0, 3.0))
print(q:prettystr())
q:invert()
print(q:prettystr())

m:fromQuaternion(q)
print(m:prettystr())

m:compose(q, v3(1.0,1.0,1.0), v3(10.0, -0.3, 13.7))
print("m: " .. m:prettystr())

local m_inv = m:clone():invert()
print("m_inv: " .. m_inv:prettystr())

local mult = matrix.Matrix4()
mult:multiplyInto(m, m_inv)
print("m*m_inv: " .. mult:prettystr())

mult:makeProjection(60.0, 1.0, 0.01, 1000.0)
print(mult:prettystr())
mult:flipProjHandedness()
print(mult:prettystr())
mult:identity()
mult:flipViewHandedness()
print(mult:prettystr())