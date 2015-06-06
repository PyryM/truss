-- dart/meshmanager.t
--
-- loads+moves meshes around according to json

class = truss_import("core/30log.lua")
json = truss_import("lib/json.lua")
stlloader = truss_import("loaders/stlloader.t")
objloader = truss_import("loaders/objloader.t")
meshutils = truss_import("mesh/mesh.t")
stringutils = truss_import("utils/stringutils.t")

local m = {}

local MeshManager = class("MeshManager")

function MeshManager:init(meshpath, renderer)
	self.meshpath = meshpath
	self.renderer = renderer
	self.geos = {}
	self.meshes = {}
	self.verbose = false
	self.highlightColor = {1.0, 0.0, 0.0}
end

function MeshManager:highlight(hset)
	print("#hset: " .. #hset)
	for meshname, mesh in pairs(self.meshes) do
		mesh.material.color = {1,1,1} -- let it be whatever the default is
	end
	for meshidx, meshname in ipairs(hset) do
		print("Looking for " .. meshname)
		if self.meshes[meshname] ~= nil then
			print("Highlighting " .. meshname)
			self.meshes[meshname].material.color = self.highlightColor
		end
	end
end

function MeshManager:getMeshList()
	local ret = {}
	for meshname, mesh in pairs(self.meshes) do
		table.insert(ret, meshname)
	end
	return ret
end

local function hasExtension(str, target)
	local ext = string.sub(str, -(#target))
	return string.lower(ext) == string.lower(target)
end

function MeshManager:translateFilename(rawfilename)
	-- strip away leading directories, change .dae into .obj
	local gps = stringutils.split("/", rawfilename)
	local basefn = gps[#gps]
	if string.lower(string.sub(basefn, -4)) == ".dae" then
		basefn = string.sub(basefn, 1, -5) .. ".obj"
	end

	return self.meshpath .. basefn
end

function MeshManager:createMesh(meshfilename)
	local fullfilename = self:translateFilename(meshfilename)
	trss.trss_log(0, "MeshManager loading [" .. fullfilename .. "]")

	if self.geos[meshfilename] == nil then
		local modeldata = nil
		if hasExtension(fullfilename, ".stl") then
			modeldata = stlloader.loadSTL(fullfilename, false) -- don't invert windings
		elseif hasExtension(fullfilename, ".obj") then
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

function MeshManager:updateMesh(mesh, quat, position, scale)
	if quat then
		local mq = mesh.quaternion
		mq.x, mq.y, mq.z, mq.w = quat[1], quat[2], quat[3], quat[4]
	end
	if position then
		local mp = mesh.position
		mp.x, mp.y, mp.z = position[1], position[2], position[3]
	end
	if scale then
		local s = mesh.scale
		s.x, s.y, s.z = scale[1], scale[2], scale[3]
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
				local scale = body["scale"]
				local m = self:getMesh(bodyname, fn)
				-- quat and pos might not be defined on the body,
				-- in which case they won't be changed
				self:updateMesh(m, quat, pos, scale)
			end
		end
	end
end

m.MeshManager = MeshManager
return m