-- grid.t
--
-- creates a basic grid

local line = require("geometry/line.t")
local m = {}

local function addLineCircle(dest, rad)
    -- create a circle
    local circlepoints = {}
    local npts = 60
    local dtheta = math.pi * 2.0 / (npts - 1)
    for i = 1,npts do
        local x = rad * math.cos(i * dtheta)
        local y = rad * math.sin(i * dtheta)
        local z = 0.0
        circlepoints[i] = {x, y, z}
    end
    table.insert(dest, circlepoints)
    return npts
end

local function addSegmentedLine(dest, v0, v1, nsteps)
    local dx = (v1[1] - v0[1]) / (nsteps - 1)
    local dy = (v1[2] - v0[2]) / (nsteps - 1)
    local dz = (v1[3] - v0[3]) / (nsteps - 1)

    local curline = {}
    local x, y, z = v0[1], v0[2], v0[3]
    for i = 0,(nsteps-1) do
        table.insert(curline, {x, y, z})
        x, y, z = x + dx, y + dy, z + dz
    end
    table.insert(dest, curline)
    return #curline
end

function m.Grid(options)
    options = options or {}

    local dx = options.spacing or 0.5
    local nx = options.numlines or 20
    local dy = dx
    local ny = nx

    local r0 = 0.0
    local dr = options.rspacing or dx
    local nr = options.numcircles or math.ceil(nx / 2)

    local x0 = -0.5 * nx * dx
    local y0 = -0.5 * ny * dy

    local x1 = x0 + nx*dx
    local y1 = y0 + ny*dy

    local lines = {}
    local npts = 0

    for ix = 0,nx do
        local x = x0 + ix*dx
        local v0 = {x, y0, 0}
        local v1 = {x, y1, 0}
        npts = npts + addSegmentedLine(lines, v0, v1, 30)
    end

    for iy = 0,ny do
        local y = y0 + iy*dy
        local v0 = {x0, y, 0}
        local v1 = {x1, y, 0}
        npts = npts + addSegmentedLine(lines, v0, v1, 30)
    end

    for ir = 1,nr do
        npts = npts + addLineCircle(lines, r0 + ir*dr)
    end

    local color = options.color or {0.7,0.7,0.7,1}
    local thickness = options.thickness or 0.05

    local theline = line.LineObject(npts, false) -- static line
    theline:setPoints(lines)
    theline.material.color:fromArray(color)
    theline.material.thickness:set(thickness)

    return theline
end

return m