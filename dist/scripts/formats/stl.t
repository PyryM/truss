-- stlloader.t
--
-- loads binary STL files

local m = {}
local Vector = require("math").Vector

m.verbose = false
m.MAXFACES = 21845 -- each face needs 3 vertices, to fit into 16 bit index
 				   -- buffer we can have at most floor(2^16 / 3) faces

local tic, toc = truss.tic, truss.toc

function m.load_stl(filename, invert)
	local starttime = tic()
	local src_message = truss.C.load_file(filename)
	if src_message == nil then
		log.error("Error: unable to open file " .. filename)
		return nil
	end

	local ret = m.parse_binary_stl(src_message.data, src_message.data_length, invert)
	truss.C.release_message(src_message)
	local dtime = toc(starttime)
	log.info("Loaded " .. filename .. " in " .. (dtime*1000.0) .. " ms")
	return ret
end

m.load = m.load_stl

-- read a little endian uint32
terra m.read_uint32_le(buffer: &uint8, startpos: uint32)
	var ret: uint32 = [uint32](buffer[startpos  ])       or
					  [uint32](buffer[startpos+1]) << 8  or
					  [uint32](buffer[startpos+2]) << 16 or
					  [uint32](buffer[startpos+3]) << 24
	return ret
end

-- read a little endian uint16
terra m.read_uint16_le(buffer: &uint8, startpos: uint32)
	var ret: uint16 = [uint16](buffer[startpos  ]) or
					  [uint16](buffer[startpos+1]) << 8
	return ret
end

-- read a uint8
terra m.read_uint8(buffer: &uint8, startpos: uint32)
	return buffer[startpos]
end

local terra sanitize_nan(v: float)
	if v == v then
		return v
	else
		return 0.0f
	end
end

terra m.read_f32(buffer: &uint8, startpos: uint32)
	var retptr: &float = [&float](&(buffer[startpos]))
	return sanitize_nan(@retptr)
end

terra m.str_to_uint8_ptr(src: &int8)
	var ret: &uint8 = [&uint8](src)
	return ret
end

function m.parse_binary_stl(databuf, datalength, invert)
	if m.verbose then
		log.debug("Going to parse a binary stl of length " .. datalength)
	end

	local faces = m.read_uint32_le( databuf, 80 )
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
		if m.read_uint32_le(databuf, index) == 0x434F4C4F and -- COLO
		   m.read_uint8(databuf, index + 4) == 0x52 and       -- R
		   m.read_uint8(databuf, index + 5) == 0x3D then      -- =

			log.warn("Warning: .stl has face colors but color parsing not implemented yet.")

			defaultR = m.read_uint8(databuf, index + 6)
			defaultG = m.read_uint8(databuf, index + 7)
			defaultB = m.read_uint8(databuf, index + 8)
			alpha    = m.read_uint8(databuf, index + 9)
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

		local nx = normalMult * m.read_f32(databuf, start)
		local ny = normalMult * m.read_f32(databuf, start + 4)
		local nz = normalMult * m.read_f32(databuf, start + 8)

		-- indices is a normal lua array and 1-indexed
		if invert then
			indices[face+1] = {offset, offset+2, offset+1}
		else
			indices[face+1] = {offset, offset+1, offset+2}
		end

		for i = 1,3 do
			local vertexstart = start + i * 12

			-- vertices and normals are normal lua arrays and hence 1-indexed
			vertices[ offset + 1 ] =  {m.read_f32(databuf, vertexstart ),
									   					   m.read_f32(databuf, vertexstart + 4 ),
									   				 		 m.read_f32(databuf, vertexstart + 8 )}

			normals[ offset + 1 ] = {nx, ny, nz}
			offset = offset + 1
		end
	end -- face loop

	return {attributes = {position = vertices, normal = normals},
	        indices = indices,
	        color = {defaultR, defaultG, defaultB, alpha}}
end

return m
