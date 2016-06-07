-- geometry/widgets.t
--
-- various geometric widgets like axis bars

local m = {}
local geoutils = require("geometry/geoutils.t")
local math = require("math")
local cylinder = require("geometry/cylinder.t")

function m.axisWidgetData(scale, length, segments)
    scale = scale or 1.0
    segments = segments or 6
    local radius = scale * 0.02
    length = length or scale

    -- local xAxis = math.Vector(1.0, 0.0, 0.0, 0.0)
    -- local yAxis = math.Vector(0.0, 1.0, 0.0, 0.0)
    -- local zAxis = math.Vector(0.0, 0.0, 1.0, 0.0)
    -- local wAxis = math.Vecotr(0.0, 0.0, 0.0, 1.0)
    --
    -- local toX = math.Matrix4():fromBasis({yAxis, xAxis, zAxis, wAxis})

    local q = math.Quaternion()
    local p = math.Vector()

    local rotations = {{0,0,math.pi/2}, {0,0,0}, {-math.pi/2,0,0}}
    local offset = length * 0.5 * 0.75
    local positions = {{offset,0,0}, {0,offset,0}, {0,0,offset}}
    local components = {}
    local rawdata = cylinder.cylinderData(radius, length, segments, true)
    geoutils.computeNormals(rawdata)
    for i = 1,3 do
        p:fromArray(positions[i])
        q:fromEuler(rotations[i])
        local mat = math.Matrix4():composeRigid(p, q)
        table.insert(components, {rawdata, mat})
    end

    return geoutils.mergeData(components, {"position", "normal"})
end

return m
