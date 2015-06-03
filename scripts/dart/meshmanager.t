-- dart/meshmanager.t
--
-- loads+moves meshes around according to json

class = truss_import("core/30log.lua")
json = truss_import("lib/json.lua")
stlloader = truss_import("loaders/stlloader.t")
objloader = truss_import("loaders/objloader.t")
meshutils = truss_import("mesh/mesh.t")

local m = {}

local MeshManager = class("MeshManager")

function MeshManager:init(meshpath, renderer)
	self.meshpath = meshpath
	self.renderer = renderer
	self.geos = {}
	self.meshes = {}
	self.verbose = false
end

local function hasExtension(str, target)
	local ext = string.sub(str, -(#target))
	return string.lower(ext) == string.lower(target)
end

function MeshManager:createMesh(meshfilename)
	local fullfilename = self.meshpath .. meshfilename
	trss.trss_log(0, "MeshManager loading [" .. fullfilename .. "]")

	if self.geos[meshfilename] == nil then
		local modeldata = nil
		if hasExtension(meshfilename, ".stl") then
			modeldata = stlloader.loadSTL(fullfilename, false) -- don't invert windings
		elseif hasExtension(meshfilename, ".obj") then
			modeldata = objloader.loadOBJ(fullfilename, false)
		else
			trss.trss_log(0, "Unsupported mesh file type: " .. meshfilename)
		end
		local geo = meshutils.Geometry():fromData(self.renderer.vertexInfo, modeldata)
		self.geos[meshfilename] = geo
	end

	local mat = {}
	local ret = meshutils.Mesh(self.geos[meshfilename], mat)
	ret.source_filename = meshfilename
	self.renderer:add(ret)

	return ret
end

function MeshManager:getMesh(meshname, meshfilename)
	local m = self.meshes[meshname]
	if m and m.source_filename == meshfilename then
		return m
	else
		trss.trss_log(0, "MeshManager creating mesh " .. meshname)
		if m then m.visible = false end -- TODO: actually release old m
		m = self:createMesh(meshfilename)
		self.meshes[meshname] = m
		return m
	end
end

function MeshManager:updateMesh(mesh, quat, position)
	if quat then
		local mq = mesh.quaternion
		mq.x, mq.y, mq.z, mq.w = quat[1], quat[2], quat[3], quat[4]
	end
	if position then
		local mp = mesh.position
		mp.x, mp.y, mp.z = position[1], position[2], position[3]
	end
	mesh:updateMatrixWorld()
end

function MeshManager:update(rawstr)
	local jdata = json:decode(rawstr)
	for skelname, skeleton in pairs(jdata) do
		for bodyname, body in pairs(skeleton) do
			-- assume one mesh per body
			if body["mesh.1"] then
				local fn = body["mesh.1"].filename
				local quat = body["rot"]
				local pos = body["trans"]
				local m = self:getMesh(bodyname, fn)
				-- quat and pos might not be defined on the body,
				-- in which case they won't be changed
				self:updateMesh(m, quat, pos)
			end
		end
	end
end

m.MeshManager = MeshManager
return m