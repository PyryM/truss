-- icosphere.t
-- 
-- generates an icosphere

local m = {}
local math = require("math")
local Vector = math.Vector

function m.icosahedronData(rad)
    -- adapted from
    -- http://blog.andreaskahler.com/2009/06/creating-icosphere-mesh-in-code.html

    -- create 12 vertices of a icosahedron
    local t = rad * (1.0 + math.sqrt(5.0)) / 2.0
    local position = {
        Vector(-rad,  t,  0),
        Vector( rad,  t,  0),
        Vector(-rad, -t,  0),
        Vector( rad, -t,  0),

        Vector( 0, -rad,  t),
        Vector( 0,  rad,  t),
        Vector( 0, -rad, -t),
        Vector( 0,  rad, -t),

        Vector( t,  0, -rad),
        Vector( t,  0,  rad),
        Vector(-t,  0, -rad),
        Vector(-t,  0,  rad)
    }
    local indices = {
        {0, 11, 5},
        {0, 5, 1},
        {0, 1, 7},
        {0, 7, 10},
        {0, 10, 11},

        {1, 5, 9},
        {5, 11, 4},
        {11, 10, 2},
        {10, 7, 6},
        {7, 1, 8},

        {3, 9, 4},
        {3, 4, 2},
        {3, 2, 6},
        {3, 6, 8},
        {3, 8, 9},

        {4, 9, 5},
        {2, 4, 11},
        {6, 2, 10},
        {8, 6, 7},
        {9, 8, 1}
    }

    return {indices = indices, attributes = {position = position}}
end

function m.icosphereData(rad, subdivisions)
    local geoutils = require("geometry/geoutils.t")

    subdivisions = subdivisions or 2
    local data = m.icosahedronData(1.0)

    for i = 1, subdivisions do
        data = geoutils.subdivide(data)
    end

    geoutils.spherize(data, rad)
    return data
end

-- creates a basic icosphere StaticGeometry with a
-- position + normal vertex layout
function m.icosphereGeo(rad, subdivisions, gname)
    local geoutils = require("geometry/geoutils.t")
    local StaticGeometry = require("gfx/geometry.t").StaticGeometry
    local sphereData = m.icosphereData(rad, subdivisions)
    geoutils.computeNormals(sphereData)
    local vertexdefs = require("gfx/vertexdefs.t")
    local vertInfo = vertexdefs.createStandardVertexType({"position", 
                                                          "normal"})
    return StaticGeometry(gname):fromData(vertInfo, sphereData)
end

return m
