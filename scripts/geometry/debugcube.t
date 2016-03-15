-- debugcube.t
-- 
-- creates a basic colored debug cube

local StaticGeometry = require("gfx/geometry.t").StaticGeometry

local m = {}
local idx = 0

function m.createGeo(name, vertexInfo)
    local positions = { {-1.0,  1.0,  1.0},
                        { 1.0,  1.0,  1.0},
                        {-1.0, -1.0,  1.0},
                        { 1.0, -1.0,  1.0},
                        {-1.0,  1.0, -1.0},
                        { 1.0,  1.0, -1.0},
                        {-1.0, -1.0, -1.0},
                        { 1.0, -1.0, -1.0} }

    local colors = { { 0.0, 0.0, 0.0, 255},
                     { 255, 0.0, 0.0, 255},
                     { 0.0, 255, 0.0, 255},
                     { 255, 255, 0.0, 255},
                     { 0.0, 0.0, 255, 255},
                     { 255, 0.0, 255, 255},
                     { 0.0, 255, 255, 255},
                     { 255, 255, 255, 255} }

    local indices = { 0, 2, 1,
                      1, 2, 3,
                      4, 5, 6, 
                      5, 7, 6,
                      0, 4, 2, 
                      4, 6, 2,
                      1, 3, 5, 
                      5, 3, 7,
                      0, 1, 4, 
                      4, 1, 5,
                      2, 6, 3, 
                      6, 7, 3 }

    if name == nil then
        name = "geo_debugcube_" .. idx
        idx = idx + 1
    end

    if vertexInfo == nil then
        vertexInfo = require("gfx/vertexdefs.t").createPosColorVertexInfo()
    end

    local cubegeo = StaticGeometry("cube"):allocate(vertexInfo, #positions, #indices)
    cubegeo:setIndices(indices)
    cubegeo:setAttribute("position", positions)
    cubegeo:setAttribute("color", colors)
    cubegeo:build()
    return cubegeo
end

return m