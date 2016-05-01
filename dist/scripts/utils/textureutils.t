-- textureutils.t
--
-- texture loading utilities

local m = {}
m.textures = {}
local nvgUtils = raw_addons.nanovg.functions
local nvgAddonPointer = raw_addons.nanovg.pointer

local terra loadTexture_mem(filename: &int8, flags: uint32)
	var w: int32 = -1
	var h: int32 = -1
	var n: int32 = -1
	var msg: &truss.truss_message = nvgUtils.truss_nanovg_load_image(nvgAddonPointer, filename, &w, &h, &n)
	--return msg
	var bmem: &bgfx.bgfx_memory = nil
	if msg ~= nil then
		bmem = bgfx.bgfx_copy(msg.data, msg.data_length)
	else
		truss.truss_log(truss.TRUSS_LOG_ERROR, "Error loading texture!")
	end
	truss.truss_release_message(msg)
	truss.truss_log(truss.TRUSS_LOG_INFO, "Creating texture...")
	var ret = bgfx.bgfx_create_texture_2d(w, h, 0, bgfx.BGFX_TEXTURE_FORMAT_RGBA8, flags, bmem)
	return ret
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
		m.textures[filename] = loadTexture_mem(filename, flags or 0)
	end
	return m.textures[filename]
end

return m
