-- stlloader.t
--
-- loads binary STL files

local m = {}

-- read a little endian uint32
terra m.readUint32LE(buffer: &uint8, startpos: uint32)
	var ret: uint32 = buffer[startpos  ]       or
					  buffer[startpos+1] << 8  or
					  buffer[startpos+2] << 16 or
					  buffer[startpos+3] << 24
	return ret
end

-- read a little endian uint16
terra m.readUint16LE(buffer: &uint8, startpos: uint32)
	var ret: uint16 = buffer[startpos  ]       or
					  buffer[startpos+1] << 8
	return ret
end

-- read a uint8
terra m.readUint8(buffer: &uint8, startpos: uint32)
	return buffer[startpos]
end

terra m.readFloat32(buffer: &uint8, startpos: uint32)
	var retptr: &float = [&float](buffer + startpos)
	return @retptr
end

-- adapted from http://threejs.org/examples/js/loaders/STLLoader.js
function m.parseBinarySTL(databuf, datalength)

	local faces = m.readUint32LE( databuf, 80 )
	local defaultR, defaultG, defaultB, alpha = 128, 128, 128, 255

	-- process STL header

	-- check for default color in header ("COLOR=rgba" sequence)
	-- by brute-forcing over the entire header space (80 bytes)
	for index = 0, 69 do -- for(index = 0; index < 80-10; ++index)
		if m.readUint32LE(databuf, index) == 0x434F4C4F and -- COLO
		   m.readUint8(databuf, index + 4) == 0x52 and      -- R
		   m.readUint8(databuf, index + 5) == 0x3D then     -- =

			if log then log("Warning: .stl has face colors but color parsing not implemented yet.") end

			defaultR = m.readUint8(databuf, index + 6)
			defaultG = m.readUint8(databuf, index + 7)
			defaultB = m.readUint8(databuf, index + 8)
			alpha    = m.readUint8(databuf, index + 9)
		end
	end

	-- file body
	local dataOffset = 84
	local faceLength = 12 * 4 + 2

	local offset = 0

	local vertices = {}
	local normals = {}
	local indices = {}

	for face = 0, faces-1 do
		local start = dataOffset + face * faceLength
		local normalX = m.readFloat32(databuf, start)
		local normalY = m.readFloat32(databuf, start + 4)
		local normalZ = m.readFloat32(databuf, start + 8)

		-- indices is a normal lua array and 1-indexed
		indices[face+1] = {offset, offset+1, offset+2}

		for i = 1,3 do
			local vertexstart = start + i * 12

			-- vertices and normals are normal lua arrays and hence 1-indexed
			vertices[ offset + 1 ] = {m.readFloat32(databuf, vertexstart ),
									  m.readFloat32(databuf, vertexstart + 4 ),
									  m.readFloat32(databuf, vertexstart + 8 )}

			normals[ offset + 1 ] = {normalX,
								     normalY,
								     normalZ}

			offset = offset + 1
		end
	end -- face loop

	return {vertices = vertices, 
	        normals = normals,
	        indices = indices,
	        color = {defaultR, defaultG, defaultB, alpha}}
end

terra m.stringToUint8Ptr(src: &int8)
	var ret: &uint8 = [&uint8](src)
	return ret
end

return m