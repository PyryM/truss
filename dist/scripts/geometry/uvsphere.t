-- geometry/uvsphere.t
--
-- creates "UV" (lat/lon) spheres

local m = {}

local math = require("math")
local Vector = math.Vector

-- the "plate carree" projection, a special case of equirectangular
function m.plateCarree(lat, lon)
    local u = 1.0 - (lon / (2*math.pi) + 0.5) -- map [-pi,pi]     => [1,0]
    local v = lat / math.pi + 0.5     -- map [-pi/2,pi/2] => [0,1]
    return u,v
end

function m.sphericalToCartesian(lat, lon, rad)
    local x = rad * math.cos(lat) * math.cos(lon)
    local y = rad * math.sin(lat)
    local z = rad * math.cos(lat) * math.sin(lon)
    return x, y, z
end

function m.uvSphereData(options)
    options = options or {}
    local projfunc = options.projfunc or m.plateCarree
    local rad = options.rad or 1.0
    local latDivs = options.latDivs or 10
    local lonDivs = options.lonDivs or 10
    local capSize = options.capSize or 5.0 * math.pi/180.0

    local lonStart = 0.0
    local lonEnd   = math.pi * 2.0

    local latStart = -((math.pi / 2.0) - capSize)
    local latEnd   =   (math.pi / 2.0) - capSize

    local dLon = (lonEnd - lonStart) / (lonDivs-1)
    local dLat = (latEnd - latStart) / (latDivs-1)

    local indices = {}

    -- insert cap vertices
    local positions = {Vector(0,1,0), Vector(0,-1,0)}
    local normals = {Vector(0,1,0), Vector(0,-1,0)}
    local uvs = {Vector(0.5, 1), Vector(0.5, 0)} -- not correct, but :effort:

    -- create remaining vertices
    for latIdx = 1,latDivs do
        for lonIdx = 1,lonDivs do
            local lat = latStart + (latIdx-1)*dLat
            local lon = lonStart + (lonIdx-1)*dLon
            local x,y,z = m.sphericalToCartesian(lat, lon, rad)
            local u,v = projfunc(lat, lon)
            table.insert(positions, Vector(x,y,z))
            table.insert(normals, Vector(x,y,z):normalize())
            table.insert(uvs, Vector(u, v))
        end
    end

    local function getVertexIndices(latidx, lonidx)
        local v0 = (latidx-1)*lonDivs + (lonidx-1) + 2
        local v1 = v0 + 1
        local v2 = v0 + lonDivs
        local v3 = v2 + 1
        return v0,v1,v2,v3
    end

    -- create 'body' triangles
    for latIdx = 1, latDivs-1 do
        for lonIdx = 1, lonDivs-1 do
            local v0,v1,v2,v3 = getVertexIndices(latIdx, lonIdx)
            table.insert(indices, {v0, v2, v1})
            table.insert(indices, {v1, v2, v3})
        end
    end

    -- create 'cap' triangles
    for lonIdx = 1, lonDivs-1 do
        local v0 = (lonIdx-1) + 2
        table.insert(indices, {v0, v0+1, 1})
        local v0 = lonDivs*(latDivs-1) + (lonIdx-1) + 2
        table.insert(indices, {v0, 0, v0+1})
    end


    return {indices = indices, attributes = {position = positions,
                                             normal = normals,
                                             texcoord0 = uvs}}
end

function m.uvSphereGeo(options, gname)
    local gfx = require("gfx")
    local uvSphereData = m.uvSphereData(options)
    local vertInfo = gfx.createStandardVertexType({"position", "normal", "texcoord0"})
    return gfx.StaticGeometry(gname):fromData(vertInfo, uvSphereData)
end


return m
