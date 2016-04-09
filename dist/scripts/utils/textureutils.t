-- textureutils.t
--
-- texture loading utilities

local m = {}
m.textures = {}
local nvgUtils = raw_addons.nanovg.functions
local nvgAddonPointer = raw_addons.nanovg.pointer

local terra loadTexture_mem(filename: &int8)
	var w: int32 = -1
	var h: int32 = -1
	var n: int32 = -1
	var msg: &trss.trss_message = nvgUtils.trss_nanovg_load_image(nvgAddonPointer, filename, &w, &h, &n)
	--return msg
	var bmem: &bgfx.bgfx_memory = nil
	if msg ~= nil then
		bmem = bgfx.bgfx_copy(msg.data, msg.data_length)
	else
		log.error("Error loading texture!")
	end
	trss.trss_release_message(msg)
	var ret = bgfx.bgfx_create_texture_2d(w, h, 0, bgfx.BGFX_TEXTURE_FORMAT_RGBA8, 0, bmem)
	return ret
end

-- function loadTexture(filename)
-- 	--return loadTexture_mem(filename)
-- 	local msg = loadTexture_mem(filename)
-- 	trss.trss_log(0, "Texture data size: " .. msg.data_length)
-- 	local bmem = bgfx.bgfx_copy(msg.data, msg.data_length)
-- 	trss.trss_release_message(msg)
-- 	return bgfx.bgfx_create_texture_2d(512, 512, 0, bgfx.BGFX_TEXTURE_FORMAT_BGRA8, 0, bmem)
-- end

function m.loadTexture(filename)
	if m.textures[filename] == nil then
		m.textures[filename] = loadTexture_mem(filename)
	end
	return m.textures[filename]
end

return m