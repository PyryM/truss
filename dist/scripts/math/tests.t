-- math/tests.t
--

local testlib = require("devtools/test.t")
local test = testlib.test

local m = {}

function m.run()
  test("intersection", m.test_intersection)
end

function m.test_intersection(t)
  local intersection = require("math/intersection.t")
  local Matrix4 = require("math/matrix.t").Matrix4
  local Vector = require("math/vec.t").Vector
  local Quaternion = require("math/quat.t").Quaternion

  local p = Vector(0, 0,  1)
  local v = Vector(0, 0, -1)
  local plane = Matrix4():identity() -- implictly plane at 0,0,0 normal Z
  local x, y, tt = intersection.plane_intersection(plane, p, v)

  t.ok(t.approx_eq(x, 0.0) and t.approx_eq(y, 0.0), "intersection: straight ahead")
  p = Vector(2, -2, 4)
  x, y, tt = intersection.plane_intersection(plane, p, v)
  t.ok(t.approx_eq(x, 2.0) and t.approx_eq(y, -2.0), "intersection: straight ahead 2")

  v = Vector(0, 0, 1)
  x, y, tt = intersection.plane_intersection(plane, p, v)
  t.ok(tt < 0, "negative time intersection")
end

return m