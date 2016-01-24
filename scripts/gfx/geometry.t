-- mesh.t
--
-- functions for loading meshes etc.

local class = require("class")
local vec = require("math/vec.t")
local quat = require("math/quat.t")
local matrix = require("math/matrix.t")
local buffers = require("mesh/buffers.t")

local Quaternion = quat.Quaternion
local Matrix4 = matrix.Matrix4
local Vector = vec.Vector

local m = {}

local Mesh = class("Mesh")
function Mesh:init(geo, mat)
	self.geo = geo
	self.mat = mat
	self.material = mat

	self.matrix = Matrix4():identity()
	self.quaternion = Quaternion():identity()
	self.position = Vector(0.0, 0.0, 0.0)
	self.scale = Vector(1.0, 1.0, 1.0)

	self.visible = true
end

function Mesh:updateMatrixWorld()
	self.matrix:compose(self.quaternion, self.scale, self.position)
end

local buffer_library_ = {} -- needed for memory management reasons?
local last_geo_idx_ = 0

local Geometry = class("Geometry")
function Geometry:init(name)
	if name then
		self.name = name
	else
		self.name = "__anonymous_geometry_" .. last_geo_idx_
		last_geo_idx_ = last_geo_idx_ + 1
	end
end

function Geometry:fromBuffers(databuffers)
	self.databuffers = databuffers
	buffer_library_[self.name] = databuffers
	return self
end

function Geometry:fromData(vertexInfo, modeldata)
	if modeldata == nil or vertexInfo == nil then return end

	local modelbuffers = buffers.allocateData(vertexInfo, #(modeldata.positions), #(modeldata.indices))
	buffers.setIndices(modelbuffers, modeldata.indices)
	buffers.setAttributesSafe(modelbuffers, "position", buffers.positionSetter, modeldata.positions)

	if modeldata.normals then
		buffers.setAttributesSafe(modelbuffers, "normal", buffers.normalSetter, modeldata.normals)
	end
	if modeldata.uvs then
		buffers.setAttributesSafe(modelbuffers, "uv", buffers.uvSetter, modeldata.uvs)
	end
	if modeldata.tangents then
		buffers.setAttributesSafe(modelbuffers, "tangent", buffers.tangentSetter, modeldata.tangents)
	end

	buffers.createStaticBGFXBuffers(modelbuffers)
	return self:fromBuffers(modelbuffers)
end

function Geometry:bindBuffers()
	local databuffers = self.databuffers

	if not databuffers then
		if not self.warned then
			log.warn("Warning: geometry [" .. self.name .. "] contains no data.")
			self.warned = true
		end
		return false
	end

	if databuffers.dynamic then
		-- for some reason set_dynamic_vertex_buffer does not take a start
		-- index argument, only the number of vertices
		bgfx.bgfx_set_dynamic_vertex_buffer(databuffers.vbh, 
											bgfx.UINT32_MAX)
		bgfx.bgfx_set_dynamic_index_buffer(databuffers.ibh, 
											0, bgfx.UINT32_MAX)
	else
		bgfx.bgfx_set_vertex_buffer(databuffers.vbh, 0, bgfx.UINT32_MAX)
		bgfx.bgfx_set_index_buffer(databuffers.ibh, 0, bgfx.UINT32_MAX)
	end

	return true
end

function Geometry:release()
	-- todo
end

m.Mesh = Mesh -- 'export' Mesh
m.Geometry = Geometry -- 'export' Geometry
return m