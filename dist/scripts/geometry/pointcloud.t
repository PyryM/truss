-- pointcloud.t
--
-- a pointcloud

-- TODO: this while thing is broken now

local class = require("class")
local math = require("math")
local Matrix4 = math.Matrix4
local Quaternion = math.Quaternion
local Vector = math.Vector
local geometry = require("gfx/geometry.t")
local Object3D = require("gfx/object3d.t").Object3D
local uniforms = require("gfx/uniforms.t")

local m = {}

local PointCloudObject = Object3D:extend("PointCloudObject")

function PointCloudObject:init(hres, vres)
    PointCloudObject.super.init(self)

    self.pwidth = 1.0
    self.pheight = 1.0
    self.hres = hres or 160
    self.vres = vres or 120
    self:createBuffers_()
    self.material = {shadername = "pointcloud",
                     pointParams = math.Vector(0.002,1.0,3.0,2.0),
                     depthParams = math.Vector(0.3333333333, -0.1111111111),
                     texColorDepth = nil}
    self.mat = self.material
end

function PointCloudObject:setDepthLimits(near, far)
    local params = self.mat.depthParams
    local a =  (far*near) / (far-near)
    local b = -near / (far-near)
    params.elem.x = a
    params.elem.y = b
    log.debug("a: " .. a .. ", b: " .. b)
end

function PointCloudObject:setPlaneSize(w,h)
    local params = self.mat.pointParams
    params.elem.z = w
    params.elem.w = h
end

function PointCloudObject:setPointSize(p)
    self.mat.pointParams.elem.x = p
end

function PointCloudObject:createBuffers_()
    local vdefs = require("gfx/vertexdefs.t")
    local vinfo = vdefs.createStandardVertexType({"position",
                                                  "normal",
                                                  "texcoord0"})
    local rawdata = m.createParticleArrayData(1.0, 1.0, -1.0,
                                              self.hres, self.vres)
    self.geo = geometry.StaticGeometry():fromData(vinfo, rawdata)
end

local PointCloudShader = class("PointCloudShader")
function PointCloudShader:init(invz, vshader, fshader)
    local pointParams = uniforms.Uniform("u_pointParams", uniforms.VECTOR, 1)
    local texColorDepth = uniforms.TexUniform("s_texColorDepth", 0)
    local matUniforms = uniforms.UniformSet()
    matUniforms:add(pointParams, "pointParams")
    matUniforms:add(texColorDepth, "texColorDepth")
    if invz then
        local depthParams = uniforms.Uniform("u_depthParams", uniforms.VECTOR, 1)
        matUniforms:add(depthParams, "depthParams")
    end
    self.uniforms = matUniforms
    local vertexProgram = vshader
    if vertexProgram == nil and invz then
        vertexProgram = "vs_points_invz"
    end
    self.program = gfx.load_program(vertexProgram or "vs_points",
                                           fshader or "fs_points")
end

-- creates an array of particles
function m.createParticleArrayData(width, height, z, wdivs, hdivs)
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
            local uv = {(ix+0.5)/wdivs, 1.0 - (iy+0.5)/hdivs}
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

m.PointCloudObject = PointCloudObject
m.PointCloudShader = PointCloudShader
return m
