-- test_objloader.t
--
-- tests for the objloader

local importpath = "../scripts/"
local emulator = require("trussemulator")

-- define truss import so that other things will work
truss_import = emulator.makeImport(importpath)

objloader = truss_import("loaders/objloader.t")
stringutils = truss_import("utils/stringutils.t")

local objfilestring = [[
# cube.obj
#
 
o cube
mtllib cube.mtl
 
v -0.500000 -0.500000 0.500000
v 0.500000 -0.500000 0.500000
v -0.500000 0.500000 0.500000
v 0.500000 0.500000 0.500000
v -0.500000 0.500000 -0.500000
v 0.500000 0.500000 -0.500000
v -0.500000 -0.500000 -0.500000
 v 0.500000 -0.500000 -0.500000 
 
vt 0.000000 0.000000
vt 1.000000 0.000000 
vt 0.000000 1.000000
 vt 1.000000 1.000000
 
vn 0.000000 0.000000 1.000000
vn 0.000000 1.000000 0.000000
vn 0.000000 0.000000 -1.000000
vn 0.000000 -1.000000 0.000000
vn 1.000000 0.000000 0.000000
vn -1.000000 0.000000 0.000000
 
g cube
usemtl cube
s 1
f 1/1/1 2/2/1 3/3/1
f 3/3/1 2/2/1 4/4/1
s 2
f 3/1/2 4/2/2 5/3/2
f 5/3/2 4/2/2 6/4/2
s 3
f 5/4/3 6/3/3 7/2/3
f 7/2/3 6/3/3 8/1/3
s 4
f 7/1/4 8/2/4 1/3/4
f 1/3/4 8/2/4 2/4/4
s 5
f 2/1/5 8/2/5 4/3/5
f 4/3/5 8/2/5 6/4/5
s 6
f 7/1/6 1/2/6 5/3/6
f 5/3/6 1/2/6 3/4/6
]]

-- modified version of the above with
-- no texture coordinates to test a file
-- with just positions and normals
local objfilestring2 = [[
# cube.obj
#
 
o cube
mtllib cube.mtl
 
v -0.500000 -0.500000 0.500000
v 0.500000 -0.500000 0.500000
v -0.500000 0.500000 0.500000
v 0.500000 0.500000 0.500000
v -0.500000 0.500000 -0.500000
 v 0.500000 0.500000 -0.500000 
v -0.500000 -0.500000 -0.500000
v 0.500000 -0.500000 -0.500000 
 
vn 0.000000 0.000000 1.000000
vn 0.000000 1.000000 0.000000
vn 0.000000 0.000000 -1.000000 
vn 0.000000 -1.000000 0.000000
vn 1.000000 0.000000 0.000000
vn -1.000000 0.000000 0.000000
 
g cube
usemtl cube
s 1
f 1//1 2//1 3//1
 f 3//1 2//1 4//1
s 2
f 3//2 4//2 5//2
f 5//2 4//2 6//2
s 3
f 5//3 6//3 7//3
f 7//3 6//3 8//3
s 4
f 7//4 8//4 1//4
f 1//4 8//4 2//4
s 5
f 2//5 8//5 4//5
f 4//5 8//5 6//5
s 6
f 7//6 1//6 5//6
f 5//6 1//6 3//6
]]

function tests0()
	local s = "v  0.0 1.0 	2.0"
	local gps = stringutils.split("%s+", s)
	assert(#gps == 4, "Wrong number of groups: 4 != " .. #gps)
	assert(gps[1] == "v", "gps[1] != v")
	assert(gps[2] == "0.0", "gps[2] != 0.0")
	assert(gps[3] == "1.0", "gps[3] != 1.0")
	assert(gps[4] == "2.0", "gps[4] != 2.0")
end

function tests1()
	local s = "    v 1.0 	"
	local s2 = "	v 1.0 "
	local ts = stringutils.strip(s)
	local ts2 = stringutils.strip(s2)
	assert(ts == "v 1.0", "Strip error: got " .. ts)
	assert(ts2 == "v 1.0", "Strip error: got " .. ts2)
end

function tests2()
	local s = "1//2"
	local gps = stringutils.split("/", s)
	assert(#gps == 3, "Wrong number of groups, expected 3 got " .. #gps)
	assert(gps[1] == "1", "gps[1] != '1'")
	assert(gps[2] == "", "gps[2] != ''")
	assert(gps[3] == "2", "gps[3] != '2'")
end

function test0()
	assert(objloader, "objloader.t didn't return a table!")
end

function formatv(v)
	local ret = ""
	for i,v2 in ipairs(v) do
		ret = ret .. v2 .. ", "
	end
	return ret
end

function printvectorlist(l)
	for i,v in ipairs(l) do print(formatv(v)) end
end

log = print

function test1()
	objloader.verbose = true
	local res = objloader.parseOBJ(objfilestring, false)
	assert(#(res.indices) == 12, "Wrong face count, expected 12 got " .. #(res.indices))
	assert(#(res.positions) == 24, "Wrong position count, expected 24, got " .. #(res.positions))
	assert(#(res.normals) == 24, "Wrong normal count, expected 24, got " .. #(res.normals))
	assert(#(res.uvs) == 24, "Wrong uv count, expected 24, got " .. #(res.uvs))
end

function test2()
	objloader.verbose = true
	local res = objloader.parseOBJ(objfilestring2, false)
	assert(#(res.indices) == 12, "Wrong face count, expected 12 got " .. #(res.indices))
	assert(#(res.positions) == 24, "Wrong position count, expected 24, got " .. #(res.positions))
	assert(#(res.normals) == 24, "Wrong normal count, expected 24, got " .. #(res.normals))
	assert(res.uvs == nil, "Got UVs but didn't expect any! #= " .. #(res.uvs or {}))
end

tests0()
tests1()
tests2()
test0()
test1()
test2()