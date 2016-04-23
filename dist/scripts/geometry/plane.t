-- plane.t
--
-- makes a (subdivided) plane

local m = {}
local math = require("math")
local Vector = math.Vector

function m.planeData(width, height, wdivs, hdivs)
    local position = {}
    local texcoord0 = {}
    local normal = {}
    local indices = {}

    local dx = width / wdivs
    local dy = height / hdivs

    local x0 = -(width / 2)
    local y0 = -(height / 2)

    -- create vertices
    for iy = 0,hdivs do
        for ix = 0,wdivs do
            local x, y = x0+(ix*dx), y0+(iy*dy)
            table.insert(position, {x,y,0})
            table.insert(texcoord0, {ix/wdivs, iy/hdivs})
            table.insert(normal, {0,0,1})
        end
    end

    local function v(ix,iy)
        return iy*(wdivs+1)+ix
    end

    -- create indices
    -- 3:(0,1) +------+ 2:(1,1)
    --         |    / |
    --         | /    |
    -- 0:(0,0) +------+ 1:(1,0)
    for iy = 0,(hdivs-1) do
        for ix = 0,(wdivs-1) do
            table.insert(indices, {v(ix,iy), v(ix+1,iy), v(ix+1,iy+1)})
            table.insert(indices, {v(ix,iy), v(ix+1,iy+1), v(ix,iy+1)})
        end
    end

    return {indices = indices,
            attributes = {position = position,
                          normal = normal,
                          texcoord0 = texcoord0}
            }
end

return m
