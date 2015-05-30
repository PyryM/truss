-- mesh.t
--
-- functions for loading meshes etc.

local class = truss_import("core/30log.lua")
local quat = truss_import("math/quat.t")
local matrix = truss_import("math/matrix.t")
local buffers = truss_import("mesh/buffers.t")

local Quaternion = quat.Quaternion
local Matrix4 = matrix.Matrix4

local m = {}

local Mesh = class("Mesh")
function Mesh:init(geo, mat)
	self.geo = geo
	self.mat = mat

	self.matrixWorld = Matrix4():identity()
	self.quaternion = Quaternion():identity()
	self.position = {x = 0.0, y = 0.0, z = 0.0}
	self.scale = {x = 1.0, y = 1.0, z = 1.0}

	self.visible = true
end

function Mesh:updateMatrixWorld()
	self.matrixWorld:compose(self.quaternion, self.scale, self.position)
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

function Geometry:release()
	-- todo
end

m.Mesh = Mesh -- 'export' Mesh
m.Geometry = Geometry -- 'export' Geometry
return m