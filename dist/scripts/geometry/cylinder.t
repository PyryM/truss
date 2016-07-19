-- geometry/cylinder.t
--
-- generates a cylinder

local m = {}
local math = require("math")
local Vector = math.Vector

function m.cylinderData(radius, height, nsegs, capped)
    capped = (capped == nil) or capped -- make it default to true

    local dtheta = 2.0 * math.pi / nsegs

    -- create vertices
    local positions = {}
    local yTop = height/2.0
    local yBot = -yTop
    for i = 1,nsegs do
        local theta = (i-1) * dtheta
        local x = math.cos(theta) * radius
        local z = math.sin(theta) * radius
        table.insert(positions, Vector(x, yTop, z, 0))
        table.insert(positions, Vector(x, yBot, z, 0))
    end

    local indices = {}
    -- tube
    for i = 0,nsegs-1 do
        local v0 = (i*2  ) % (nsegs * 2)
        local v1 = (i*2+1) % (nsegs * 2)
        local v2 = (i*2+2) % (nsegs * 2)
        local v3 = (i*2+3) % (nsegs * 2)
        table.insert(indices, {v0, v2, v1})
        table.insert(indices, {v1, v2, v3})
    end
    -- caps
    if capped then
        table.insert(positions, Vector(0, yTop, 0, 0))
        table.insert(positions, Vector(0, yBot, 0, 0))

        local vTop = #(positions)-2
        local vBot = vTop + 1

        -- need to copy side vertices so they can have different normals in
        -- order to get a sharp edge on the caps
        for i = 1,nsegs*2 do
            table.insert(positions, Vector():copy(positions[i]))
        end

        for i = 0,nsegs-1 do
            local v0 = (vBot + 1) + (i*2  ) % (nsegs * 2)
            local v1 = (vBot + 1) + (i*2+2) % (nsegs * 2)
            table.insert(indices, {v1,   v0,   vTop})
            table.insert(indices, {v0+1, v1+1, vBot})
        end
    end

    return {
        indices = indices,
        attributes = {
            position = positions
        }
    }
end

function m.cylinderGeo(radius, height, nsegs, capped, gname)
    local gfx = require("gfx")
    local geoutils = require("geometry/geoutils.t")
    local cylinderData = m.cylinderData(radius, height, nsegs, capped)
    geoutils.computeNormals(cylinderData)
    local vertInfo = gfx.createStandardVertexType({"position", "normal", "texcoord0"})
    return gfx.StaticGeometry(gname):fromData(vertInfo, cylinderData)
end

return m
