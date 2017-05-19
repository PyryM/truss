-- gfx/texture.t
--
-- various texture utilities

local class = require('class')
local math = require("math")
local m = {}

-- utils for creating static textures from files, memory
local m = {}
m._textures = {}
local nvg_utils = truss.addons.nanovg.functions
local nvg_pointer = truss.addons.nanovg.pointer

local terra load_texture_mem(filename: &int8, flags: uint32)
  var w: int32 = -1
  var h: int32 = -1
  var n: int32 = -1
  var msg: &truss.C.Message = nvg_utils.truss_nanovg_load_image(nvg_pointer, filename, &w, &h, &n)
  --return msg
  var bmem: &bgfx.memory_t = nil
  if msg ~= nil then
  bmem = bgfx.copy(msg.data, msg.data_length)
  else
  truss.C.log(truss.C.LOG_ERROR, "Error loading texture!")
  end
  truss.C.release_message(msg)
  truss.C.log(truss.C.LOG_INFO, "Creating texture...")
  var ret = bgfx.create_texture_2d(w, h, false, 1, bgfx.TEXTURE_FORMAT_RGBA8,
                                  flags, bmem)
  return ret
end

local function load_texture_bgfx(filename, flags)
  local msg = truss.C.load_file(filename)
  if msg == nil then return nil end
  local bmem = bgfx.copy(msg.data, msg.data_length)
  truss.C.release_message(msg)
  return bgfx.create_texture(bmem, flags, 0, nil)
end

terra m.create_texture_from_data(w: int32, h: int32, src: &uint8, srclen: uint32, flags: uint32) : bgfx.texture_handle_t
  var bmem: &bgfx.memory_t = nil
  if src ~= nil then
    bmem = bgfx.copy(src, srclen)
  else
    truss.C.log(truss.C.LOG_ERROR, "Error creating texture: null pointer")
    var ret : bgfx.texture_handle_t
    ret.idx = bgfx.INVALID_HANDLE
    return ret
  end
  var ret = bgfx.create_texture_2d(w, h, false, 1, bgfx.TEXTURE_FORMAT_RGBA8,
                                   flags, bmem)
  return ret
end

m._texture_loaders = {
  [".png"] = load_texture_mem,
  [".jpg"] = load_texture_mem,
  [".ktx"] = load_texture_bgfx,
  [".dds"] = load_texture_bgfx,
  [".pvr"] = load_texture_bgfx
}

function m._load_texture(filename, flags)
  local extension = string.lower(string.sub(filename, -4, -1))
  local loader = m._texture_loaders[extension]
  if loader then
    return loader(filename, flags or 0)
  else
    log.error("Unknown texture type " .. extension)
  end
end

-- load a texture as a texture object
function m.load_texture(filename, flags)
  if not m._textures[filename] then
    m._textures[filename] = m.Texture(filename, flags)
  end
  return m._textures[filename]
end

local struct texture_data {
	w: int32;
	h: int32;
	n: int32;
	data: &truss.C.Message;
}

local terra load_texture_data(filename: &int8, dest: &texture_data)
	dest.data = nvg_utils.truss_nanovg_load_image(nvg_pointer, filename,
												 &dest.w, &dest.h, &dest.n)
end

-- load just the raw pixel data of a texture
function m.load_texture_data(filename)
	local temp = terralib.new(texture_data)
	load_texture_data(filename, temp)
	if temp.w <= 0 or temp.h <=0 or temp.n <= 0 then
		log.error("couldn't load tex data: " .. temp.w .. " " .. temp.h .. " "
				  .. temp.n)
		truss.C.release_message(temp.data)
		return nil
	end
	local dsize = temp.w*temp.h*temp.n
	local ndata = terralib.new(uint8[temp.w*temp.h*temp.n])
	for i = 0,dsize-1 do
		ndata[i] = temp.data.data[i]
	end
	truss.C.release_message(temp.data)
	return {w = temp.w, h = temp.h, n = temp.n, data = ndata}
end

local Texture = class("Texture")
m.Texture = Texture
function Texture:init(filename, flags)
  if filename then self:load(filename, flags) end
end

function Texture:is_valid()
  return self._handle ~= nil
end

function Texture:load(filename, flags)
  self:release()
  self._handle = m._load_texture(filename, flags)
end

function Texture:blit_copy(src, options)
  if not self.blit_dest then
    truss.error("Cannot blit: texture does not have bgfx.blit_dest flag!")
    return
  end
  truss.error("Not implemented yet!")
  -- TODO
end

function Texture:read_data(options, onsuccess)
  truss.error("Not implemented yet!")
  -- TODO
  -- bgfx.blit(viewid, m._read_back_tex, dMip, dX, dY, dZ,
  --                   m.tex,            sMip, sX, sY, sZ, w, h, d)
  -- bgfx.read_texture(m._read_back_tex, m._readbackbuffer.data, 0)
  -- gfx.schedule(function()
  --   onsuccess(m.texw, m.texh, m._readbackbuffer)
  -- end)
end

function Texture:release()
  if self._handle ~= nil then
    bgfx.destroy_texture(self._handle)
    self._handle = nil
  end
end

-- for when you need to create a texture in memory
local MemTexture = class("MemTexture")
m.MemTexture = MemTexture

local formats = {
  R8 = {uint8, bgfx.TEXTURE_FORMAT_R8, 1, 1},
  RGBA8 = {uint8, bgfx.TEXTURE_FORMAT_BGRA8, 4, 4},
  RG16  = {uint16, bgfx.TEXTURE_FORMAT_RG16, 2, 4}
}

function MemTexture:init(w,h,fmt,flags)
  self.width = w or 64
  self.height = h or 64
  self.fmt = fmt or "RGBA8"
  local fmtinfo = formats[self.fmt]
  local datatype, bgfxformat, nchannels, psize =
        fmtinfo[1], fmtinfo[2], fmtinfo[3], fmtinfo[4]
  self.data = terralib.new(datatype[w*h*nchannels])
  self.datasize = w*h*psize
  self.pitch = self.width * psize

  flags = flags or math.combine_flags(bgfx.TEXTURE_MIN_POINT,
                                      bgfx.TEXTURE_MAG_POINT,
                                      bgfx.TEXTURE_MIP_POINT)

  -- Pass in nil as the data to allow us to update this texture later
  self._handle = bgfx.create_texture_2d(w, h, false, 1, bgfxformat, flags, nil)
end

function MemTexture:update()
  bgfx.update_texture_2d(self._handle, 0,
                          0, 0, self.width, self.height,
                          bgfx.make_ref(self.data, self.datasize),
                          self.pitch)
end

return m
