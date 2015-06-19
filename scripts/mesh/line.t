-- line.t
--
-- a shader-based projected line

local class = truss_import("core/30log.lua")
local bufferutils = truss_import("mesh/buffers.t")
local Matrix4 = truss_import("math/matrix.t").Matrix4
local Quaternion = truss_import("math/quat.t").Quaternion

local Line = class("Line")

local internals = {}
struct internals.VertexType {
	position: float[3];
	normal: float[3];
	color: float[4];
}

local terra declareLineVertexType(vertDecl: &bgfx.bgfx_vertex_decl_t)
	bgfx.bgfx_vertex_decl_begin(vertDecl, bgfx.bgfx_get_renderer_type())
	bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_POSITION, 3, 
								bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
	bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_NORMAL, 3, 
								bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
	bgfx.bgfx_vertex_decl_add(vertDecl, bgfx.BGFX_ATTRIB_COLOR0, 4, 
								bgfx.BGFX_ATTRIB_TYPE_FLOAT, false, false)
	bgfx.bgfx_vertex_decl_end(vertDecl)
end

local function getVertexInfo()
	if internals.vertInfo == nil then
		local vspec = terralib.new(bgfx.bgfx_vertex_decl_t)
		declareLineVertexType(vspec)
		internals.vertInfo = {vertType = internals.VertexType, 
							  vertDecl = vspec, 
							  attributes = {position=true, normal=true, color=true}}
	end

	return internals.vertInfo
end

function Line:init(maxpoints, dynamic)
	self.maxpoints = maxpoints
	self.dynamic = not not dynamic -- coerce to boolean
	self:createBuffers_()

	self.matrixWorld = Matrix4():identity()
	self.quaternion = Quaternion():identity()
	self.position = {x = 0.0, y = 0.0, z = 0.0}
	self.scale = {x = 1.0, y = 1.0, z = 1.0}

	self.visible = true
end

function Line:updateMatrixWorld()
	self.matrixWorld:compose(self.quaternion, self.scale, self.position)
end

local function packVec3(dest, arr)
	-- dest is a 0-indexed terra type, arr is a 1-index lua table
	dest[0] = arr[1]
	dest[1] = arr[2]
	dest[2] = arr[3]
end

local function packVertex(dest, curPoint, prevPoint, nextPoint, dir)
	packVec3(dest.position, curPoint)
	packVec3(dest.normal, prevPoint)
	packVec3(dest.color, nextPoint)
	dest.color[3] = dir
end

function Line:appendSegment_(segpoints, vertidx, idxidx)
	local npts = #segpoints
	local nlinesegs = npts - 1
	local startvert = vertidx

	-- emit two vertices per point
	local vbuf = self.buffers.verts
	for i = 1,npts do
		local curpoint = segpoints[i]
		-- shader detects line start if prevpoint==curpoint
		--                line end   if nextpoint==curpoint
		local prevpoint = segpoints[i-1] or curpoint
		local nextpoint = segpoints[i+1] or curpoint

		packVertex(vbuf[vertidx]  , curpoint, prevpoint, nextpoint,  1.0)
		packVertex(vbuf[vertidx+1], curpoint, prevpoint, nextpoint, -1.0)

		vertidx = vertidx + 2
	end

	-- emit two faces (six indices) per segment
	local ibuf = self.buffers.indices
	for i = 1,nlinesegs do
	    ibuf[idxidx+0] = startvert + 0 
	    ibuf[idxidx+1] = startvert + 1 
	    ibuf[idxidx+2] = startvert + 2 
	    ibuf[idxidx+3] = startvert + 2 
	    ibuf[idxidx+4] = startvert + 1 
	    ibuf[idxidx+5] = startvert + 3 
		idxidx = idxidx + 6
		startvert = startvert + 2
	end

	return vertidx, idxidx
end

function Line:createBuffers_()
	local vinfo = getVertexInfo()
	local nvertices = self.maxpoints * 2
	local nfaces = self.maxpoints * 2
	trss.trss_log(0, "Allocating line buffers...")
	self.buffers = bufferutils.allocateData(vinfo, nvertices, nfaces)
end

-- Update the line buffers: for a static line (dynamic == false)
-- this will only work once
function Line:setPoints(lines)
	-- try to determine whether somebody has passed in a single line
	-- rather than a list of lines
	if type(lines[1][1]) == "number" then
		trss.trss_log(0, "Warning: Line:updateBuffers expects a list of lines!")
		trss.trss_log(0, "Warning: Please pass a single line as {line}")
		lines = {lines}
	end

	-- update data
	local npts = 0
	local vertidx, idxidx = 0, 0
	local nlines = #lines
	for i = 1,nlines do
		local newpoints = #(lines[i])
		if npts + newpoints > self.maxpoints then
			trss.trss_log(0, "Exceeded max points! ["
								.. (npts+newpoints) 
								.. "/" .. self.maxpoints .. "]")
			break
		end
		vertidx, idxidx = self:appendSegment_(lines[i], vertidx, idxidx)
	end

	if self.dynamic then
		-- createDynamicBGFXBuffers is smart enough to update the buffers if
		-- you try to create the buffers multiple times
		bufferutils.createDynamicBGFXBuffers(self.buffers)
	else
		trss.trss_log(0, "Creating static buffers...")
		-- this will have no effect if the static
		-- buffers have already been created 
		bufferutils.createStaticBGFXBuffers(self.buffers)
	end

	self.geo = {databuffers = self.buffers}
end

local LineMaterial = class("LineMaterial")

function LineMaterial:init(color, thickness)
	local sutils = truss_import("utils/shaderutils.t")
	self.program = sutils.loadProgram("vs_line", "fs_line")
	-- TODO: share uniforms??
	self.color_u = bgfx.bgfx_create_uniform("u_color", 
							bgfx.BGFX_UNIFORM_TYPE_VEC4, 1)
	self.thickness_u = bgfx.bgfx_create_uniform("u_thickness",
							bgfx.BGFX_UNIFORM_TYPE_VEC4, 1)
	self.color4f = terralib.new(float[4])
	self.thickness4f = terralib.new(float[4])
	for i = 1,4 do 
		self.color4f[i-1] = color[i] or 1.0 
	end
	self.thickness4f[0] = thickness or 1.0
end

function LineMaterial:apply()
	bgfx.bgfx_set_program(self.program)
	bgfx.bgfx_set_uniform(self.color_u, self.color4f, 1)
	bgfx.bgfx_set_uniform(self.thickness_u, self.thickness4f, 1)
	--trss.trss_log(0, "Applying material...")
end

function Line:createDefaultMaterial(color, thickness)
	self.material = LineMaterial(color or {1,1,1,1}, thickness)
end

return Line