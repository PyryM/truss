-- dart/prmeshmanager.t
--
-- loads+places meshes around
-- digests json from prpy.serialization

local dartmanager = require('dart/meshmanager.t')
local m = {}

local PrMeshManager = dartmanager.MeshManager:extend("PrMeshManager")

-- only need to override update
function PrMeshManager:update(rawstr)
	local jdata = json:decode(rawstr)
	if jdata.data == nil then return end
	jdata = jdata.data
	if jdata.bodies == nil then return end
	jdata = jdata.bodies
	end

	for idx, body in ipairs(jdata) do
		self:updateBody(body)
	end
end

function PrMeshManager:updateLink(bodyname, linkdata)
	local lname = linkdata["_name"] or "unknown_link"

	local quat = linkdata.info._t.orientation
	local pos = linkdata.info._t.position

	local geos = linkdata.info._vgeometryinfos

	for i, geo in ipairs(geos) do
		local scale = geo._vRenderScale
		local fn = geo._filenamerender or ""
		if fn ~= "" then
			local fullname = bodyname .. "." .. lname .. "." .. i
			local m = self:getMesh(fullname, fn)
			self:updateMesh(m, quat, pos, scale)
		end
	end
end

function PrMeshManager:updateBody(bodydata)
	local name = bodydata.name or "unknown_body"
	local links = bodydata.links
	if links == nil then return end
	for i, link in ipairs(links) do
		self:updateLink(name, link)
	end
end

return m