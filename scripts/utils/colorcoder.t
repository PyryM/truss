-- colorcoder.t
--
-- utils for encoding (via nanovg) data into an image

local colorcoder = {}

struct colorcoder.FloatUnion {
	union {
		fval: float;
		bvals: uint8[4];
	}
}

-- Encodes data (which is assumed to be a list of integers [0,255]) into a
-- series of blockw x blockh mono blocks
function colorcoder.encodeMonoBlocks(nvg, data, x0, y0, blockw, blockh)
	local nblocks = #data
	local x = x0
	for dataidx, dval in ipairs(data) do
		nanovg.nvgBeginPath(nvg)
		nanovg.nvgRect(nvg, x, y0, blockw, blockh)
		nanovg.nvgFillColor(nvg, nanovg.nvgRGBA(dval, dval, dval, 255))
		nanovg.nvgFill(nvg)
		x = x + blockw
	end
end

local tempunion_ = terralib.new(colorcoder.FloatUnion)

-- Turns a float into an array of 'bytes'
function colorcoder.floatToBytes(f)
	local u = tempunion_
	u.fval = f
	return u.bvals[0], u.bvals[1], u.bvals[2], u.bvals[3]
end

-- Turns a list of floats into a list of 4x 'bytes'
function colorcoder.floatListToBytes(flist)
	local ret = {}
	local rl = 1
	for idx, f in ipairs(flist) do
		local b0,b1,b2,b3 = colorcoder.floatToBytes(f)
		ret[rl+0] = b0
		ret[rl+1] = b1
		ret[rl+2] = b2
		ret[rl+3] = b3
		rl = rl + 4
	end
	return ret
end

-- Big convenience function for encoding a list of float
function colorcoder.encodeFloats(nvg, flist, x0, y0, bw, bh)
	local bytelist = colorcoder.floatListToBytes(flist)
	colorcoder.encodeMonoBlocks(nvg, bytelist, x0, y0, bw, bh)
end

return colorcoder