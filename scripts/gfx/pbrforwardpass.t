-- pbrforwardpass.t
--
-- a physics based rendering forward pass

local class = require("class")
local loadProgram = require("utils/shaderutils.t").loadProgram
local uniforms = require("gfx/uniforms.t")
local Vector = require("math/vec.t").Vector

local m = {}

function PBRForwardPass:init()
    self.vertexInfo = vertexdefs.createPosNormalUVVertexInfo()

    -- load programs and create uniforms for it
    self.pgm    = loadProgram("vs_untextured",    "fs_untextured")
    self.texpgm = loadProgram("vs_basictextured", "fs_basictextured")

    self.lightUniforms = uniforms.Uniforms()
    self.lightUniforms:add("u_lightDir", uniforms.XYZW, 4)
    self.lightUniforms:add("u_lightRgb", uniforms.RGBA, 4)

    self.modelUniforms = uniforms.Uniforms()
    self.modelUniforms:add("u_baseColor", uniforms.RGBA, 1)
    self.modelUniforms:add("s_texAlbedo", uniforms.TEXTURE, 1)

    self.viewid = 0

    -- set default lights
    self:setLightDirections({
            Vector( 1.0,  1.0,  0.0),
            Vector(-1.0,  1.0,  0.0),
            Vector( 0.0, -1.0,  1.0),
            Vector( 0.0, -1.0, -1.0)})

    local off = {0.0, 0.0, 0.0}
    self:setLightColors({
            {0.4, 0.35, 0.3},
            {0.6, 0.5, 0.5},
            {0.1, 0.1, 0.2},
            {0.1, 0.1, 0.2}})

    -- set model color
    self:setModelColor(1.0,1.0,1.0)
end

function PBRForwardPass:setLightDirections(dirs)
    local lightDirs = self.lightUniforms.uniforms.u_lightDir.val
    for i = 1,4 do
        local cdir = dirs[i]:normalize().elem
        lightDirs[i-1].x = cdir.x
        lightDirs[i-1].y = cdir.y
        lightDirs[i-1].z = cdir.z
    end
end

function PBRForwardPass:setLightColors(colors)
    local lightDirs = self.lightUniforms.uniforms.u_lightRgb.val
    for i = 1,self.numLights do
        self.lightColors[i-1].r = colors[i][1]
        self.lightColors[i-1].g = colors[i][2]
        self.lightColors[i-1].b = colors[i][3]
    end
end

function PBRForwardPass:setModelColor(r, g, b)
    local modelColor = self.modelUniforms.uniforms.u_baseColor.val
    modelColor.r = r
    modelColor.g = g
    modelColor.b = b
end
 
function PBRForwardPass:applyMaterial(material)
    if material.apply then
        if material.program then
            self.activeProgram = material.program
        end
        material:apply()
    elseif material.texture then
        self.activeProgram = self.texpgm
        local mc = (self.useColors and material.color) or {}
        self:setModelColor(mc[1] or 1, mc[2] or 1, mc[3] or 1)
        bgfx.bgfx_set_texture(0, self.s_texAlbedo, material.texture, bgfx.UINT32_MAX)
    else
        material = material or {}
        local mc = (self.useColors and material.color) or {}
        self:setModelColor(mc[1] or 1, mc[2] or 1, mc[3] or 1)
        self.activeProgram = self.pgm
    end
end

function PBRForwardPass:renderGeo(geo, mtx, material)
    if not geo:bindBuffers() then
        return
    end

    bgfx.bgfx_set_transform(mtx.data, 1) -- only one matrix in array
    if material then
        self:applyMaterial(material)
    end

    bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
    bgfx.bgfx_submit(self.viewid, self.activeProgram, 0)
end

function PBRForwardPass:render()
    -- setup basic stuff
    self:setViewMatrices()
    self:updateUniforms()

    local rootmat = self.rootmat
    local tempmat = self.tempmat

    for i,v in ipairs(self.objects) do
        if v.visible then
            if self.autoUpdateMatrices and v.updateMatrixWorld then v:updateMatrixWorld() end
            local mat = v.matrixWorld or v.matrix
            if mat and v.geo then
                tempmat:multiplyInto(rootmat, mat)
                self:renderGeo(v.geo, tempmat, v.material)
            end
        end
    end
end

return m