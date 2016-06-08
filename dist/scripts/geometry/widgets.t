-- geometry/widgets.t
--
-- various geometric widgets like axis bars

local m = {}
local geoutils = require("geometry/geoutils.t")
local math = require("math")
local cylinder = require("geometry/cylinder.t")

function m.createCylinderLine(y0, y1, radius, segs, target, parentmat)
    local length = y1 - y0
    local center = (y0 + y1) / 2.0

    local data = cylinder.cylinderData(radius, length, segs, true)
    geoutils.computeNormals(data)
    local offset = math.Vector(0.0, center, 0.0)
    local mat = math.Matrix4():makeTranslation(offset)
    mat:leftMultiply(parentmat)
    table.insert(target, {data, mat})
end

function m.axisWidgetData(scale, length, segments)
    scale = scale or 1.0
    segments = segments or 12
    local radius = scale * 0.02
    length = length or scale

    local q = math.Quaternion()
    local p = math.Vector():zero()

    local rotations = {{0,0,math.pi/2}, {0,0,0}, {-math.pi/2,0,0}}
    local bsize = scale * 0.1
    local lines = {
        {{-length*0.25, length}},
        {{-length*0.25, length-bsize*2}, {length-bsize, length}},
        {{-length*0.25, length-bsize*4}, {length-bsize*3,length-bsize*2}, {length-bsize, length}}
    }

    local components = {}

    for i = 1,3 do
        q:fromEuler(rotations[i])
        local mat = math.Matrix4():composeRigid(p, q)
        for _,s in ipairs(lines[i]) do
            m.createCylinderLine(s[1], s[2], radius, segments, components, mat)
        end
    end

    return geoutils.mergeData(components, {"position", "normal"})
end

function m.axisWidgetGeo(geoName, scale, length, segments)
    return geoutils.toBasicGeo(geoName, m.axisWidgetData(scale, length, segments))
end

return m
