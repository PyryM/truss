-- simple_renderer.t
--
-- a minimal renderer (one material, no scenegraph)

local class = truss_import("core/30log.lua")
local quat = truss_import("math/quat.t")
local matrix = truss_import("math/matrix.t")
local Matrix4 = matrix.Matrix4
local buffers = truss_import("mesh/buffers.t")
local mesh = truss_import("mesh/mesh.t")
local vertexdefs = truss_import("mesh/vertexdefs.t")

local m = {}

local function loadProgram(vshadername, fshadername)
	local sutils = truss_import("utils/shaderutils.t")
	return sutils.loadProgram(vshadername, fshadername)
end

struct m.LightDir {
	x: float;
	y: float;
	z: float;
	w: float;
}

struct m.LightColor {
	r: float;
	g: float;
	b: float;
	a: float;
}

local SimpleRenderer = class("SimpleRenderer")
function SimpleRenderer:init(width, height)
	self.width, self.height = width, height
	self.objects = {}

	self.vertexInfo = vertexdefs.createPosNormalUVVertexInfo()

	-- load programs and create uniforms for it
	self.pgm    = loadProgram("vs_untextured",    "fs_untextured")
	self.texpgm = loadProgram("vs_basictextured", "fs_basictextured")
	self.numLights = 4
	self.u_lightDir = bgfx.bgfx_create_uniform("u_lightDir", bgfx.BGFX_UNIFORM_TYPE_VEC4, self.numLights)
	self.u_lightRgb = bgfx.bgfx_create_uniform("u_lightRgb", bgfx.BGFX_UNIFORM_TYPE_VEC4, self.numLights)
	self.u_baseColor = bgfx.bgfx_create_uniform("u_baseColor", bgfx.BGFX_UNIFORM_TYPE_VEC4, 1)
	self.s_texAlbedo = bgfx.bgfx_create_uniform("s_texAlbedo", bgfx.BGFX_UNIFORM_TYPE_INT1, 1)

	self.lightDirs = nil
	self.lightColors = nil
	self.modelColor = nil

	self.lightDirs = terralib.new(m.LightDir[self.numLights])
	self.lightColors = terralib.new(m.LightColor[self.numLights])
	self.modelColor = terralib.new(float[4])

	self.autoUpdateMatrices = true
	self.useColors = true

	-- create matrices
	self.projmat = Matrix4():makeProjection(60.0, width / height, 0.01, 100.0)
	--self.projmat:flipProjHandedness() -- change handedness from LH to RH
	self.viewmat = Matrix4():identity()
	--self.viewmat:flipViewHandedness() -- blame directx

	self.rootmat = Matrix4():identity()
	self.tempmat = Matrix4()

	self.viewid = 0

	-- set default lights
	self:setLightDirections({
			{ 1.0,  1.0,  0.0},
			{-1.0,  1.0,  0.0},
			{ 0.0, -1.0,  1.0},
			{ 0.0, -1.0, -1.0}})

	local off = {0.0, 0.0, 0.0}
	self:setLightColors({
			{0.4, 0.35, 0.3},
			{0.6, 0.5, 0.5},
			{0.1, 0.1, 0.2},
			{0.1, 0.1, 0.2}})

	-- set model color
	self:setModelColor(1.0,1.0,1.0)
end

function SimpleRenderer:setProgram(vsname, fsname)
	self.pgm = loadProgram(vsname, fsname)
end

function SimpleRenderer:setTexProgram(vsname, fsname)
	self.texpgm = loadProgram(vsname, fsname)
end

function SimpleRenderer:setCameraTransform(cammat)
	self.viewmat:invert(cammat)
end

function SimpleRenderer:setRootTransform(rootmat)
	self.rootmat:copy(rootmat)
end

function SimpleRenderer:setViewMatrices()
	bgfx.bgfx_set_view_transform(self.viewid, self.viewmat.data, self.projmat.data)
end

function SimpleRenderer:updateUniforms()
	bgfx.bgfx_set_uniform(self.u_lightDir, self.lightDirs, self.numLights)
	bgfx.bgfx_set_uniform(self.u_lightRgb, self.lightColors, self.numLights)
end

function normalizeDir(d)
	local m = 1.0 / math.sqrt(d[1]*d[1] + d[2]*d[2] + d[3]*d[3])
	return {m*d[1], m*d[2], m*d[3]}
end

function SimpleRenderer:setLightDirections(dirs)
	for i = 1,self.numLights do
		local cdir = normalizeDir(dirs[i])
		self.lightDirs[i-1].x = cdir[1]
		self.lightDirs[i-1].y = cdir[2]
		self.lightDirs[i-1].z = cdir[3]
	end
end

function SimpleRenderer:setLightColors(colors)
	for i = 1,self.numLights do
		self.lightColors[i-1].r = colors[i][1]
		self.lightColors[i-1].g = colors[i][2]
		self.lightColors[i-1].b = colors[i][3]
	end
end

function SimpleRenderer:setModelColor(r, g, b)
	self.modelColor[0] = r
	self.modelColor[1] = g
	self.modelColor[2] = b
	bgfx.bgfx_set_uniform(self.u_baseColor, self.modelColor, 1)
end

-- only supports adding 
function SimpleRenderer:add(obj)
	table.insert(self.objects, obj)
end

function SimpleRenderer:renderGeo(geo, mtx, material)
	if not geo.databuffers then
		if not geo.warned then
			trss.trss_log(0, "Warning: geo [" .. geo.name .. "] contains no data.")
			geo.warned = true
		end
		return 
	end

	bgfx.bgfx_set_transform(mtx.data, 1) -- only one matrix in array
	if material and material.apply then
		material:apply()
	elseif material and material.texture then
		bgfx.bgfx_set_program(self.texpgm)
		local mc = (self.useColors and material.color) or {}
		self:setModelColor(mc[1] or 1, mc[2] or 1, mc[3] or 1)
		bgfx.bgfx_set_texture(0, self.s_texAlbedo, material.texture, bgfx.UINT32_MAX)
	else
		material = material or {}
		local mc = (self.useColors and material.color) or {}
		self:setModelColor(mc[1] or 1, mc[2] or 1, mc[3] or 1)
		bgfx.bgfx_set_program(self.pgm)
	end

	if geo.databuffers.dynamic then
		-- for some reason set_dynamic_vertex_buffer does not take a start
		-- index argument, only the number of vertices
		bgfx.bgfx_set_dynamic_vertex_buffer(geo.databuffers.vbh, 
											bgfx.UINT32_MAX)
		bgfx.bgfx_set_dynamic_index_buffer(geo.databuffers.ibh, 
											0, bgfx.UINT32_MAX)
	else
		bgfx.bgfx_set_vertex_buffer(geo.databuffers.vbh, 0, bgfx.UINT32_MAX)
		bgfx.bgfx_set_index_buffer(geo.databuffers.ibh, 0, bgfx.UINT32_MAX)
	end

	bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
	bgfx.bgfx_submit(self.viewid, 0)
end

function SimpleRenderer:render()
	-- setup basic stuff
	self:setViewMatrices()
	self:updateUniforms()

	local rootmat = self.rootmat
	local tempmat = self.tempmat

	for i,v in ipairs(self.objects) do
		if v.visible then
			if self.autoUpdateMatrices and v.updateMatrixWorld then v:updateMatrixWorld() end
			if v.matrixWorld and v.geo then
				tempmat:multiplyInto(rootmat, v.matrixWorld)
				self:renderGeo(v.geo, tempmat, v.material)
			end
		end
	end
end

m.SimpleRenderer = SimpleRenderer
return m