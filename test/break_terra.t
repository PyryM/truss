struct FourBytes {
	b: uint8[4];
}

-- NaN (0xB3, 0x79, 0xBE, 0xFF)
badbytes = terralib.new(FourBytes)
badbytes.b[0] = 0xB3 -- 179
badbytes.b[1] = 0x79 -- 121
badbytes.b[2] = 0xBE -- 190
badbytes.b[3] = 0xFF -- 255

-- 1.0
goodbytes = terralib.new(FourBytes)
goodbytes.b[0] = 0x00
goodbytes.b[1] = 0x00
goodbytes.b[2] = 0x80
goodbytes.b[3] = 0x3F

terra crashme(input: &uint8)
	var retptr: &float = [&float](input)
	return @retptr
end

terra returnNaN()
	var ret: float = 0.0f / 0.0f
	return ret
end

print("This will work: " .. crashme(goodbytes.b))

local cval = crashme(badbytes.b)

print(type(cval))

local nan = returnNaN()
local foo = 1.0 * nan

print("got here...")

local bla = {}
bla[1] = 1.0 * cval