-- geometry/tests.t
--

local testlib = require("devtools/test.t")
local test = testlib.test
local geoutils = require("geometry/geoutils.t")
local m = {}

function m.run()
  test("geoutils", m.test_geoutils)
end

local function make_tri()
  local Vec = require("math").Vector
  return {
    indices = {{0, 1, 2}},
    attributes = {
      position = {Vec(1, 0, 0), Vec(0, 1, 0), Vec(0, 0, 1)},
      texcoord0 = {Vec(0, 0), Vec(0, 1), Vec(1, 0)}
    }
  }
end

local function make_quad()
  local Vec = require("math").Vector
  return {
    indices = {{0, 1, 2}, {2, 3, 0}},
    attributes = {
      position = {Vec(0, 0, 0), Vec(1, 0, 0), Vec(0, 1, 0), Vec(0, 0, 1)},
      texcoord0 = {Vec(0, 0), Vec(0, 1), Vec(1, 0), Vec(1, 1)}
    }
  }
end

function m.test_geoutils(t)
  -- subdivision
  local tri = make_tri()
  local subdivided_tri = geoutils.subdivide(tri)
  t.expect(#(subdivided_tri.indices or {}), 4, "subdivide: tri faces")
  t.expect(#(subdivided_tri.attributes.position or {}), 6, "subdivide: tri vertices")
  t.expect(#(subdivided_tri.attributes.texcoord0 or {}), 6, "subdivide: tri texcoords")
  subdivided_tri = geoutils.subdivide(subdivided_tri)
  t.expect(#(subdivided_tri.indices or {}), 16, "subdivide^2: tri faces")
  t.expect(#(subdivided_tri.attributes.position or {}), 15, "subdivide^2: tri vertices")
  t.expect(#(subdivided_tri.attributes.texcoord0 or {}), 15, "subdivide^2: tri texcoords")

  -- normal computation
  local quad = make_quad()
  geoutils.compute_normals(quad)
  t.expect(#(quad.attributes.normal or {}), 4, "normals computed: ")

  -- triangle splitting
  local split_tris = geoutils.split_triangles(quad)
  t.expect(#(split_tris.indices or {}), 2, "split: faces")
  t.expect(#(split_tris.attributes.position or {}), 6, "split: vertices")
  t.expect(#(split_tris.attributes.texcoord0 or {}), 6, "split: texcoords")
end

return m