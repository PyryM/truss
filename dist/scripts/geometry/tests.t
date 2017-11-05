-- geometry/tests.t
--

local testlib = require("devtools/test.t")
local test = testlib.test
local Vec = require("math").Vector
local m = {}

function m.run()
  test("geometries", m.test_geometries)
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
  local geoutils = require("geometry/geoutils.t")

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
  local hull = geoutils.convex_hull(tpoints)
  t.expect(#(hull.indices or {}), 4, "tetra hull: faces")
  t.expect(#(hull.attributes.position or {}), 4, "tetra hull: vertices")
  tpoints = tetra_points()
  table.insert(tpoints, Vec(0.1, 0.1, 0.1)) -- this point should be inside hull
  local hull2 = geoutils.convex_hull(tpoints)
  t.expect(#(hull2.indices or {}), 4, "tetra+1 hull: faces")
  t.expect(#(hull2.attributes.position or {}), 4, "tetra+1 hull: vertices")
  t.ok(check_windings(Vec(0.1, 0.1, 0.1, 0), hull2), "tetra+1 hull: incorrect windings")
end

function m.test_geometries(t)
  local geo = require("geometry")

  local cube = geo.cube_data()
  t.expect(#(cube.indices or {}), 12, "cube: triangular faces")

  local cylinder = geo.cylinder_data{segments = 7}
  t.expect(#(cylinder.indices or {}), 7*4, "cylinder: triangular faces")
  local uncapped_cylinder = geo.cylinder_data{segments = 7, capped = false}
  t.expect(#(uncapped_cylinder.indices or {}), 7*2, 
            "uncapped cylinder: triangular faces")

  local icosphere = geo.icosphere_data{detail = 1}
  t.expect(#(icosphere.indices or {}), 20*4, "icosphere (detail=1): faces")
  icosphere = geo.icosphere_data{detail = 2}
  t.expect(#(icosphere.indices or {}), 20*4*4, "icosphere (detail=2): faces")

  local lat_divs, lon_divs = 5, 7
  local n_uvsphere_faces = lat_divs*lon_divs*2 + lon_divs*2
  local uvsphere = geo.uvsphere_data{lat_divs = lat_divs, lon_divs = lon_divs}
  t.expect(#(uvsphere.indices or {}), n_uvsphere_faces, "uvsphere: faces")

  local plane = geo.plane_data{segments = 4}
  t.expect(#(plane.indices or {}), 4*4*2, "plane (4x4): faces")
  plane = geo.plane_data{wdivs = 3, hdivs = 7}
  t.expect(#(plane.indices or {}), 3*7*2, "plane (3x7): faces")

  local quad_points = {Vec(1, 1), Vec(-1, 1), Vec(-1, -1), Vec(1, -1)}
  local poly = geo.polygon_data{pts = quad_points}
  t.expect(#(poly.indices or {}), 4-2, "convex quad polygon: faces")
  local cross_points = {Vec( 1,  1), Vec(   0, 0.5), 
                        Vec(-1,  1), Vec(-0.5,   0), 
                        Vec(-1, -1), Vec(   0,-0.5),
                        Vec( 1, -1), Vec( 0.5,   0)}
  poly = geo.polygon_data{pts = cross_points}
  t.expect(#(poly.indices or {}), 8-2, "concave poly (8v): faces")
end

return m