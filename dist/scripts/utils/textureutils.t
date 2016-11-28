-- textureutils.t
--
-- texture loading utilities

local m = {}
m.textures = {}
local nvgUtils = truss.rawAddons.nanovg.functions
local nvgAddonPointer = truss.rawAddons.nanovg.pointer

local terra loadTexture_mem(filename: &int8, flags: uint32)
	var w: int32 = -1
	var h: int32 = -1
	var n: int32 = -1
	var msg: &truss.C.Message = nvgUtils.truss_nanovg_load_image(nvgAddonPointer, filename, &w, &h, &n)
	--return msg
	var bmem: &bgfx.bgfx_memory = nil
	if msg ~= nil then
		bmem = bgfx.bgfx_copy(msg.data, msg.data_length)
	else
		truss.C.log(truss.C.LOG_ERROR, "Error loading texture!")
	end
	truss.C.release_message(msg)
	truss.C.log(truss.C.LOG_INFO, "Creating texture...")
	var ret = bgfx.bgfx_create_texture_2d(w, h, 0, bgfx.BGFX_TEXTURE_FORMAT_RGBA8, flags, bmem)
	return ret
end

local function loadTexture_bgfx(filename, flags)
	local msg = truss.C.load_file(filename)
	if msg == nil then return nil end
	local bmem = bgfx.bgfx_copy(msg.data, msg.data_length)
	truss.C.release_message(msg)
	return bgfx.bgfx_create_texture(bmem, flags, 0, nil)
end

-- function loadTexture(filename)
-- 	--return loadTexture_mem(filename)
-- 	local msg = loadTexture_mem(filename)
-- 	truss.truss_log(0, "Texture data size: " .. msg.data_length)
-- 	local bmem = bgfx.bgfx_copy(msg.data, msg.data_length)
-- 	truss.truss_release_message(msg)
-- 	return bgfx.bgfx_create_texture_2d(512, 512, 0, bgfx.BGFX_TEXTURE_FORMAT_BGRA8, 0, bmem)
-- end

function m.loadTexture(filename, flags)
	if m.textures[filename] == nil then
		local extension = string.lower(string.sub(filename, -4, -1))
		if extension == ".png" or extension == ".jpg" then
			m.textures[filename] = loadTexture_mem(filename, flags or 0)
		elseif extension == ".ktx" or extension == ".dds" or extension == ".pvr" then
			m.textures[filename] = loadTexture_bgfx(filename, flags or 0)
		else
			log.error("Unknown texture type " .. extension)
		end
	end
	return m.textures[filename]
end

return m
