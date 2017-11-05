-- geometry/tests.t
--

local testlib = require("devtools/test.t")
local test = testlib.test
local geoutils = require("geometry/geoutils.t")
local Vec = require("math").Vector
local m = {}

function m.run()
  test("geoutils", m.test_geoutils)
end

local function make_tri()
  return {
    indices = {{0, 1, 2}},
    attributes = {
      position = {Vec(1, 0, 0), Vec(0, 1, 0), Vec(0, 0, 1)},
      texcoord0 = {Vec(0, 0), Vec(0, 1), Vec(1, 0)}
    }
  }
end

local function tetra_points()
  return {Vec(0, 0, 0), Vec(1, 0, 0), Vec(0, 1, 0), Vec(0, 0, 1)}
end

local function make_quad()
  return {
    indices = {{0, 1, 2}, {2, 3, 0}},
    attributes = {
      position = {Vec(0, 0, 0), Vec(0, 1, 0), Vec(1, 0, 0), Vec(1, 1, 0)},
      texcoord0 = {Vec(0, 0), Vec(0, 1), Vec(1, 0), Vec(1, 1)}
    }
  }
end

-- test if triangles are correctly wound to face away from p_center
local function check_windings(p_center, data)
  local vx, vy, vn = Vec(), Vec(), Vec()
  local pts = data.attributes.position
  for _, face in ipairs(data.indices) do
    local i1, i2, i3 = face[1] + 1, face[2] + 1, face[3] + 1
    vx:sub(pts[i1],pts[i2])
    vy:sub(pts[i1],pts[i3])
    vn:cross(vx, vy):normalize3()
    vx:sub(p_center, pts[i1])
    if vx:dot(vn) > 0.0 then return false end
  end
  return true
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

  -- brute force hull computation
  local tpoints = tetra_points()
  local hull = geoutils.brute_force_hull(tpoints)
  t.expect(#(hull.indices or {}), 4, "tetra hull: faces")
  t.expect(#(hull.attributes.position or {}), 4, "tetra hull: vertices")
  tpoints = tetra_points()
  table.insert(tpoints, Vec(0.1, 0.1, 0.1)) -- this point should be inside hull
  local hull2 = geoutils.brute_force_hull(tpoints)
  t.expect(#(hull2.indices or {}), 4, "tetra+1 hull: faces")
  t.expect(#(hull2.attributes.position or {}), 4, "tetra+1 hull: vertices")
  t.ok(check_windings(Vec(0.1, 0.1, 0.1, 0), hull2), "tetra+1 hull: incorrect windings")
end

return m