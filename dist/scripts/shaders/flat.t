-- shaders/flat.t
--
-- unlit shaders/materials

local m = {}
local class = require("class")
local math = require("math")
local gfx = require("gfx")
local shaderutils = require("utils/shaderutils.t")

local FlatShader = class("FlatShader")
function FlatShader:init(options)
    local opts = options or {}
    local matUniforms = gfx.UniformSet()
    matUniforms:add(gfx.Uniform("u_baseColor", gfx.VECTOR, 1), "diffuse")
    local fragmentShaderName = "fs_flatsolid"
    if options.texture then
        matUniforms:add(gfx.TexUniform("s_texAlbedo", 0), "diffuseMap")
        fragmentShaderName = "fs_flattextured"
    end

    self.uniforms = matUniforms
    self.globals = nil
    self.program = shaderutils.loadProgram("vs_flat", fragmentShaderName)
end

function FlatMaterial(options)
    local ret = {}
    if options.diffuseMap then
        ret.shadername = "flatTextured"
    else
        ret.shadername = "flatSolid"
    end
    ret.diffuse = options.diffuse or math.Vector(1.0,1.0,1.0,1.0)
    ret.diffuseMap = options.diffuseMap
    return ret
end

m.FlatShader = FlatShader
m.FlatMaterial = FlatMaterial
return m
