-- buffers.t
--
-- functions for creating and manipulating vertex/index buffers

local m = {}

m.vertex_index_type = uint16

-- allocateData
-- 
-- allocates vertex and index buffer storage, but doesn't
-- create the buffers (you need to load in the actual data first!)
function m.allocateData(vertInfo, nvertices, nfaces)
	local data = {}
	local nindices = nfaces * 3 -- assume triangles
	data.vertInfo = vertInfo
	data.verts = terralib.new(vertInfo.vertType[nvertices])
	data.nvertices = nvertices
	data.indices = terralib.new(m.vertex_index_type[nindices])
	data.nindices = nindices
	data.vertDataSize = sizeof(vertInfo.vertType[nvertices])
	data.indexDataSize = sizeof(m.vertex_index_type[nindices])
	return data
end

-- setIndices
--
-- sets face indices from a list of lists
-- e.g. {{0,1,2}, {1,2,3}, {3,4,5}, {5,2,1}}
function m.setIndices(data, facelist)
	local nfaces = #facelist
	local nindices = nfaces * 3 -- assume triangles
	if data.nindices ~= nindices then
		error("Wrong number of indices, expected " 
				.. (data.nindices or "nil")
				.. " got " .. (nindices or "nil"))
		return
	end

	local dest = data.indices
	local destIndex = 0
	for f = 1,nfaces do
		dest[destIndex]   = facelist[f][1] or 0
		dest[destIndex+1] = facelist[f][2] or 0
		dest[destIndex+2] = facelist[f][3] or 0
		destIndex = destIndex + 3
	end
end

-- makeSetter
--
-- makes a function to set an attribute name from a 
-- number of values
function m.makeSetter(attribname, nvals)
	if nvals > 1 then
		return function(vdata, vindex, attribVal)
			for i = 1,nvals do
				-- vdata is C-style struct and so zero indexed
				vdata[vindex][attribname][i-1] = attribVal[i]
			end
		end
	else 
		return function(vdata, vindex, attribVal)
			vdata[vindex][attribname] = attribVal
		end
	end
end

-- convenience setters
m.positionSetter = m.makeSetter("position", 3)
m.normalSetter = m.makeSetter("normal", 3)
m.uvSetter = m.makeSetter("uv", 2)
m.colorSetter = m.makeSetter("color", 4)

-- setter for when you just need random colors, ignores attribVal
function m.randomColorSetter(vdata, vindex, attribVal)
	vdata[vindex].color[0] = math.random() * 255.0
	vdata[vindex].color[1] = math.random() * 255.0
	vdata[vindex].color[2] = math.random() * 255.0
	vdata[vindex].color[3] = math.random() * 255.0
end

-- setAttributesSafe
--
-- like set attributes but checks if the attribute exists
function m.setAttributesSafe(data, attribname, setter, attriblist)
	if data.vertInfo.attributes[attribname] == nil then
		trss.trss_log(0, "Buffer does not have attribute " .. attribname)
		return
	end
	m.setAttributes(data, setter, attriblist)
end

-- setAttributes
--
-- sets vertex attributes (e.g, positions) given a list
-- of attributes (per vertex) and a setter for that attrib
-- setter(vertData, vertexIndex, attribValue)
function m.setAttributes(data, setter, attriblist)
	local nvertices = #attriblist
	if data.nvertices ~= nvertices then
		error("Wrong number of vertices, expected " 
				.. (data.nvertices or "nil")
				.. " got " .. (nvertices or "nil"))
		return
	end

	local dest = data.verts
	for v = 1,nvertices do
		-- dest (data.verts) is a C-style array so zero indexed
		setter(dest, v-1, attriblist[v])
	end
end

-- createStaticBGFXBuffers
--
-- creates static bgfx buffers from vertex and index data
-- the created buffers are added to the data table as
-- data.vbh and data.ibh
--
-- if recreate is set then any old buffers will be destroyed
-- and remade from the new data. 
-- Otherwise, if old buffers exist, the function
-- will simply return without makaing any chanages.
function m.createStaticBGFXBuffers(data, recreate)
	local flags = 0

	if (data.vbh or data.ibh) and (not recreate) then
		return
	end

	if data.vbh then
		bgfx.bgfx_destroy_vertex_buffer(data.vbh)
	end
	if data.ibh then
		bgfx.bgfx_destroy_index_buffer(data.ibh)
	end

	-- Create static bgfx buffers
	-- Warning! This only wraps the data, so make sure it doesn't go out
	-- of scope EVER (TODO: sane memory management)
	data.vbh = bgfx.bgfx_create_vertex_buffer(
		  bgfx.bgfx_make_ref(data.verts, data.vertDataSize),
		  data.vertInfo.vertDecl, flags )

	data.ibh = bgfx.bgfx_create_index_buffer(
		  bgfx.bgfx_make_ref(data.indices, data.indexDataSize))
end

return m