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

-- creates an array of particles
function m.particleArray(width, height, z, wdivs, hdivs)
    local position = {}
    local texcoord0 = {}
    local normal = {}
    local indices = {}

    local dx = width / wdivs
    local dy = height / hdivs

    local x0 = -(width / 2) + (dx / 2)
    local y0 = -(height / 2) + (dy / 2)

    -- 3:(-1, 1) +------+ 2:(1, 1)
    --           |    / |
    --           | /    |
    -- 0:(-1,-1) +------+ 1:(1,-1)
    local normals = {{-1,-1,0}, {1,-1,0}, {1,1,0}, {-1,1,0}}
    local vpos = 0

    for ix = 0,wdivs-1 do
        for iy = 0,hdivs-1 do
            local x, y = x0+(ix*dx), y0+(iy*dy)
            -- all four vertices share the same position and texcoord0
            -- but have different normals (shader will expand based on normal)
            local p = {x, y, z}
            local uv = {(ix+0.5)/wdivs, (iy+0.5)/hdivs}
            for ii = 1,4 do
                table.insert(position, p)
                table.insert(texcoord0, uv)
                table.insert(normal, normals[ii])
            end
            table.insert(indices, {vpos+0, vpos+1, vpos+2})
            table.insert(indices, {vpos+0, vpos+2, vpos+3})
            vpos = vpos + 4
        end
    end

    return {indices = indices,
            attributes = {position = position,
                          normal = normal,
                          texcoord0 = texcoord0}
            }
end
