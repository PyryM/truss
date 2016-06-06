-- geometry/widgets.t
--
-- various geometric widgets like axis bars

local m = {}
local geoutils = require("geometry/geoutils.t")
local math = require("math")

function m.axisWidgetData(scale, length, segments)
    scale = scale or 1.0
    length = length or scale
    segments = segments or 20.0

    local xAxis = math.Vector(1.0, 0.0, 0.0, 0.0)
    local yAxis = math.Vector(0.0, 1.0, 0.0, 0.0)
    local zAxis = math.Vector(0.0, 0.0, 1.0, 0.0)


end

return m
