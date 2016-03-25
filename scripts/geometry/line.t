-- line.t
--
-- a shader-based projected line

local class = require("class")
local math = require("math")
local Matrix4 = math.Matrix4
local Quaternion = math.Quaternion
local Vector = math.Vector
local geometry = require("gfx/geometry.t")
local Object3D = require("gfx/object3d.t").Object3D
local uniforms = require("gfx/uniforms.t")
local shaderutils = require("utils/shaderutils.t")

local m = {}

local LineObject = Object3D:extend("LineObject")

local internals = {}
struct internals.VertexType {
    position: float[3];
    normal: float[3];
    color0: float[4];
}

local terra declareLineVertexType(vertDecl: &bgfx.bgfx_vertex_decl_t)
    bgfx.bgfx_vertex_decl_begin(vertDecl, bgfx.bgfx_get_renderer_type())
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_POSITION, 3, 
                                bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_NORMAL, 3, 
                                bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
    bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_COLOR0, 4, 
                                bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
    bgfx.bgfx_vertex_decl_end(vertDecl)
end

local function getVertexInfo()
    if internals.vertInfo == nil then
        local vspec = terralib.new(bgfx.bgfx_vertex_decl_t)
        declareLineVertexType(vspec)
        internals.vertInfo = {vertType = internals.VertexType, 
                              vertDecl = vspec, 
                              attributes = {position=3, normal=3, color0=4}}
    end

    return internals.vertInfo
end

function LineObject:init(maxpoints, dynamic)
    LineObject.super.init(self)

    self.maxpoints = maxpoints
    self.dynamic = not not dynamic -- coerce to boolean
    self:createBuffers_()
    self.material = m.LineMaterial()
    self.mat = self.material
end

local function packVec3(dest, arr)
    -- dest is a 0-indexed terra type, arr is a 1-index lua table
    dest[0] = arr[1]
    dest[1] = arr[2]
    dest[2] = arr[3]
end

local function packVertex(dest, curPoint, prevPoint, nextPoint, dir)
    packVec3(dest.position, curPoint)
    packVec3(dest.normal, prevPoint)
    packVec3(dest.color0, nextPoint)
    dest.color0[3] = dir
end

function LineObject:appendSegment_(segpoints, vertidx, idxidx)
    local npts = #segpoints
    local nlinesegs = npts - 1
    local startvert = vertidx

    -- emit two vertices per point
    local vbuf = self.geo.verts
    for i = 1,npts do
        local curpoint = segpoints[i]
        -- shader detects line start if prevpoint==curpoint
        --                line end   if nextpoint==curpoint
        local prevpoint = segpoints[i-1] or curpoint
        local nextpoint = segpoints[i+1] or curpoint

        packVertex(vbuf[vertidx]  , curpoint, prevpoint, nextpoint,  1.0)
        packVertex(vbuf[vertidx+1], curpoint, prevpoint, nextpoint, -1.0)

        vertidx = vertidx + 2
    end

    -- emit two faces (six indices) per segment
    local ibuf = self.geo.indices
    for i = 1,nlinesegs do
        ibuf[idxidx+0] = startvert + 0 
        ibuf[idxidx+1] = startvert + 1 
        ibuf[idxidx+2] = startvert + 2 
        ibuf[idxidx+3] = startvert + 2 
        ibuf[idxidx+4] = startvert + 1 
        ibuf[idxidx+5] = startvert + 3 
        idxidx = idxidx + 6
        startvert = startvert + 2
    end

    return vertidx, idxidx
end

function LineObject:createBuffers_()
    local vinfo = getVertexInfo()
    log.debug("Allocating line buffers...")
    if self.dynamic then
        self.geo = geometry.StaticGeometry()
    else
        self.geo = geometry.DynamicGeometry()
    end
    self.geo:allocate(vinfo, self.maxpoints * 2, self.maxpoints * 6)
end

-- Update the line buffers: for a static line (dynamic == false)
-- this will only work once
function LineObject:setPoints(lines)
    -- try to determine whether somebody has passed in a single line
    -- rather than a list of lines
    if type(lines[1][1]) == "number" then
        log.warn("Warning: Line:updateBuffers expects a list of lines!")
        log.warn("Warning: Please pass a single line as {line}")
        lines = {lines}
    end

    -- update data
    local npts = 0
    local vertidx, idxidx = 0, 0
    local nlines = #lines
    for i = 1,nlines do
        local newpoints = #(lines[i])
        if npts + newpoints > self.maxpoints then
            log.error("Exceeded max points! ["
                                .. (npts+newpoints) 
                                .. "/" .. self.maxpoints .. "]")
            break
        end
        vertidx, idxidx = self:appendSegment_(lines[i], vertidx, idxidx)
    end

    self.geo:update()
end

local LineShader = class("LineShader")
function LineShader:init()
    local color = uniforms.Uniform("u_color", uniforms.VECTOR, 1)
    local thickness = uniforms.Uniform("u_thickness", uniforms.VECTOR, 1)
    local matUniforms = uniforms.UniformSet()
    matUniforms:add(color, "color")
    matUniforms:add(thickness, "thickness")

    self.uniforms = matUniforms
    self.program = shaderutils.loadProgram("vs_line", "fs_line")
end

local function LineMaterial(pass)
    return {shadername = pass or "line",
            color = math.Vector(1.0,0.2,0.1,1.0),
            thickness = math.Vector(1.0)}
end

m.LineObject = LineObject
m.LineShader = LineShader
m.LineMaterial = LineMaterial

return m