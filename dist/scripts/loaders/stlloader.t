-- stlloader.t
--
-- loads binary STL files

local m = {}
local Vector = require("math").Vector

m.verbose = false
m.MAXFACES = 21845 -- each face needs 3 vertices, to fit into 16 bit index
 				   -- buffer we can have at most floor(2^16 / 3) faces

function m.loadSTL(filename, invert)
	local starttime = tic()
	local srcMessage = truss.truss_load_file(filename)
	if srcMessage == nil then
		log.error("Error: unable to open file " .. filename)
		return nil
	end

	local ret = m.parseBinarySTL(srcMessage.data, srcMessage.data_length, invert)
	truss.truss_release_message(srcMessage)
	local dtime = toc(starttime)
	log.info("Loaded " .. filename .. " in " .. (dtime*1000.0) .. " ms")
	return ret
end

-- read a little endian uint32
terra m.readUint32LE(buffer: &uint8, startpos: uint32)
	var ret: uint32 = [uint32](buffer[startpos  ])       or
					  [uint32](buffer[startpos+1]) << 8  or
					  [uint32](buffer[startpos+2]) << 16 or
					  [uint32](buffer[startpos+3]) << 24
	return ret
end

-- read a little endian uint16
terra m.readUint16LE(buffer: &uint8, startpos: uint32)
	var ret: uint16 = [uint16](buffer[startpos  ]) or
					  [uint16](buffer[startpos+1]) << 8
	return ret
end

-- read a uint8
terra m.readUint8(buffer: &uint8, startpos: uint32)
	return buffer[startpos]
end

terra santizeNaN(v: float)
	if v == v then
		return v
	else
		return 0.0f
	end
end

terra m.readFloat32(buffer: &uint8, startpos: uint32)
	var retptr: &float = [&float](&(buffer[startpos]))
	return santizeNaN(@retptr)
end

terra m.stringToUint8Ptr(src: &int8)
	var ret: &uint8 = [&uint8](src)
	return ret
end

function m.parseBinarySTL(databuf, datalength, invert)
	if m.verbose then
		log.debug("Going to parse a binary stl of length " .. datalength)
	end

	local faces = m.readUint32LE( databuf, 80 )
	if m.verbose then
		log.debug("STL contains " .. faces .. " faces.")
	end

	if faces > m.MAXFACES then
		log.warn("Warning: STL contains >2^16 vertices, will need 32bit index buffer")
	end

	local defaultR, defaultG, defaultB, alpha = 128, 128, 128, 255

	-- process STL header

	-- check for default color in header ("COLOR=rgba" sequence)
	-- by brute-forcing over the entire header space (80 bytes)
	for index = 0, 69 do -- for(index = 0; index < 80-10; ++index)
		if m.readUint32LE(databuf, index) == 0x434F4C4F and -- COLO
		   m.readUint8(databuf, index + 4) == 0x52 and      -- R
		   m.readUint8(databuf, index + 5) == 0x3D then     -- =

			log.warn("Warning: .stl has face colors but color parsing not implemented yet.")

			defaultR = m.readUint8(databuf, index + 6)
			defaultG = m.readUint8(databuf, index + 7)
			defaultB = m.readUint8(databuf, index + 8)
			alpha    = m.readUint8(databuf, index + 9)
		end
	end

	if m.verbose then
		log.debug("stl color: " .. defaultR
							.. " " .. defaultG
							.. " " .. defaultB
							.. " " .. alpha)
	end

	-- file body
	local dataOffset = 84
	local faceLength = 12 * 4 + 2

	local offset = 0

	local vertices = {}
	local normals = {}
	local indices = {}

	local normalMult = 1.0
	if invert then normalMult = -1.0 end

	for face = 0, faces-1 do
		local start = dataOffset + face * faceLength

		local normalX = normalMult * m.readFloat32(databuf, start)
		local normalY = normalMult * m.readFloat32(databuf, start + 4)
		local normalZ = normalMult * m.readFloat32(databuf, start + 8)

		-- indices is a normal lua array and 1-indexed
		if invert then
			indices[face+1] = {offset, offset+2, offset+1}
		else
			indices[face+1] = {offset, offset+1, offset+2}
		end

		for i = 1,3 do
			local vertexstart = start + i * 12

			-- vertices and normals are normal lua arrays and hence 1-indexed
			vertices[ offset + 1 ] =  {m.readFloat32(databuf, vertexstart ),
									   m.readFloat32(databuf, vertexstart + 4 ),
									   m.readFloat32(databuf, vertexstart + 8 )}

			normals[ offset + 1 ] = {normalX,
								     normalY,
								     normalZ}

			offset = offset + 1
		end
	end -- face loop

	return {attributes = {
				position = vertices,
	        	normal = normals
	        	},
	        indices = indices,
	        color = {defaultR, defaultG, defaultB, alpha}}
end

return m
