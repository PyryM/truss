-- shaders/pbr.t
--
-- defines a basic pbr shader and material

local m = {}
local class = require("class")
local math = require("math")
local uniforms = require("gfx/uniforms.t")
local shaderutils = require("utils/shaderutils.t")

local PBRShader = class("PBRShader")
function PBRShader:init()
    local baseColor = uniforms.Uniform("u_baseColor", uniforms.VECTOR, 4)
    local pbrParams = uniforms.Uniform("u_pbrParams", uniforms.VECTOR, 4)
    local matUniforms = uniforms.UniformSet()
    matUniforms:add(baseColor, "diffuse")
    matUniforms:add(pbrParams, "pbrParams")

    local lightDirs = uniforms.Uniform("u_lightDir", uniforms.VECTOR, 4)
    local lightColors = uniforms.Uniform("u_lightRgb", uniforms.VECTOR, 4)
    local lightUniforms = uniforms.UniformSet()
    lightUniforms:add(lightDirs, "lightDirs")
    lightUniforms:add(lightColors, "lightColors")

    self.uniforms = matUniforms
    self.globals = lightUniforms
    self.program = shaderutils.loadProgram("vs_basicpbr", "fs_basicpbr_x4")
end

local PBRMaterial = class("PBRMaterial")
function PBRMaterial:init(pass)
    self.shadername = pass or "solid"
    self.vals = {}
    self.vals.diffuse = math.Vector(0.2,0.2,0.1,1.0)
    self.vals.pbrParams = math.Vector(1.0, 1.0, 1.0, 0.6)
end

function PBRMaterial:roughness(value)
    self.vals.pbrParams.elem.w = value*value
    return self
end

function PBRMaterial:tint(r,g,b)
    local e = self.vals.pbrParams.elem
    e.x, e.y, e.z = r, g, b
    return self
end

function PBRMaterial:diffuse(r,g,b)
    self.vals.diffuse:set(r,g,b,1.0)
    return self
end

m.PBRShader = PBRShader
m.PBRMaterial = PBRMaterial
return m