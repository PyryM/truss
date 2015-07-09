-- pbr_renderer.t
--
-- a minimal pbr renderer

local class = require("class")
local simple_renderer = require("renderers/simple_renderer.t")
local loadProgram = require("utils/shaderutils.t").loadProgram

local m = {}

local PBRRenderer = simple_renderer.SimpleRenderer:extend("PBRRenderer")
function PBRRenderer:init(width, height)
	PBRRenderer.super.init(self, width, height)

	-- load programs and create uniforms for it
	self.pgm    = loadProgram("vs_basicpbr",    "fs_basicpbr")
	self.texpgm = loadProgram("vs_basicpbr",    "fs_basicpbr")

	self.u_pbrParams = bgfx.bgfx_create_uniform("u_pbrParams", bgfx.BGFX_UNIFORM_TYPE_VEC4, 1)
	self.pbrParams = terralib.new(float[4])
end

function PBRRenderer:setQuality(qualval)
	if qualval < 0.9 then
		self.pgm    = loadProgram("vs_basicpbr",    "fs_basicpbr")
		self.texpgm = loadProgram("vs_basicpbr",    "fs_basicpbr")
	else
		self.pgm    = loadProgram("vs_basicpbr",    "fs_basicpbr_x4")
		self.texpgm = loadProgram("vs_basicpbr",    "fs_basicpbr_x4")
	end
end

function PBRRenderer:setPBRParams(tintR, tintG, tintB, roughness)
	self.pbrParams[0] = tintR
	self.pbrParams[1] = tintG
	self.pbrParams[2] = tintB
	self.pbrParams[3] = roughness * roughness
	bgfx.bgfx_set_uniform(self.u_pbrParams, self.pbrParams, 1)
end

function PBRRenderer:applyMaterial(material)
	if material.apply then
		material:apply()
	elseif material.texture then
		bgfx.bgfx_set_program(self.texpgm)
		local mc = (self.useColors and material.color) or {}
		self:setModelColor(mc[1] or 1, mc[2] or 1, mc[3] or 1)
		local roughness = material.roughness or 0.4
		local tint = material.fresnel or {}
		self:setPBRParams(tint[1] or 0.8, tint[2] or 0.8, tint[3] or 0.9, roughness)
		bgfx.bgfx_set_texture(0, self.s_texAlbedo, material.texture, bgfx.UINT32_MAX)
	else
		material = material or {}
		local mc = (self.useColors and material.color) or {}
		self:setModelColor(mc[1] or 0.1, mc[2] or 0.1, mc[3] or 0.1)
		local roughness = material.roughness or 0.4
		local tint = material.fresnel or {}
		self:setPBRParams(tint[1] or 0.8, tint[2] or 0.8, tint[3] or 0.9, roughness)
		bgfx.bgfx_set_program(self.pgm)
	end
end

m.PBRRenderer = PBRRenderer
return m