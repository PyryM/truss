-- gfx/texture.t
--
-- textures

local class = require("class")
local math = require("math")
local fmt = require("gfx/formats.t")

local m = {}

local Texture = class("Texture")
local Texture2d = Texture:extend("Texture2d")
local Texture3d = Texture:extend("Texture3d")
local TextureCube = Texture:extend("TextureCube")

m.Texture2d = Texture2d
m.TextureCube = TextureCube
m.Texture3d = Texture3d

function Texture:init(options)
  self:_raw_set_flags(options.flags)
  self.dynamic = options.dynamic or false
  self.has_mips = false
  self.width = options.width
  self.height = options.height
  self.depth = options.depth
  self.format = options.format or fmt.TEX_BGRA8
end

function Texture:release()
  if self._handle then
    bgfx.destroy_texture(self._handle)
    self._handle = nil
    self.cdata = nil
    self.cdatasize = nil
  end
end
Texture.destroy = Texture.release

function Texture:_set_or_create_data(options)
  if options.cdata and options.cdatasize then
    self.cdata, self.cdatasize = options.cdata, options.cdatasize
    if options.commit ~= false then
      self:commit()
    end
  elseif options.allocate ~= false then
    self:_allocate_data()
    -- Don't commit empty newly allocated data
  end
end

function Texture:_raw_set_flags(flags)
  self._cflags, self.flags = m.combine_tex_flags(flags or {})
end

function Texture:is_renderable()
  local f = self.flags
  return f.render_target or f.rt_msaa or f.rt_write_only
end

function Texture:is_blittable()
  return self.flags.blit_dest
end

function Texture:_raw_set_handle(handle, info)
  self._handle = handle
  self.width = info.width
  self.height = info.height
  self.depth = info.depth
  self.has_mips = info.numMips > 0
  self.array_count = info.numLayers
  self.is_cubemap = info.cubeMap
  self.dynamic = false
  self.format = fmt.find_format_from_enum(info.format)
end

function Texture2d:init(options)
  if not options then return end
  Texture2d.super.init(self, options)
  self.depth = 1
  self:_set_or_create_data(options)
end

function Texture3d:init(options)
  if not options then return end
  Texture3d.super.init(self, options)

  self:_set_or_create_data(options)
end

function TextureCube:init(options)
  if not options then return end
  TextureCube.super.init(self, options)
  self.width = options.size
  self.height = options.size
  self.size = options.size
  self.depth = 1
  self.is_cubemap = true
  self:_set_or_create_data(options)
end

function Texture:commit()
  if self._handle then
    truss.error("Cannot commit texture twice.")
  end
  log.debug("Committing texture.")
  self:_create_handle()
  return self
end

function Texture2d:update()
  if not self.dynamic then
    truss.error("Cannot update non-dynamic texture!")
  end
  local pitch = self.width * self.format.pixel_size
  bgfx.update_texture_2d(self._handle, 0, 0,
                          0, 0, self.width, self.height,
                          bgfx.make_ref(self.cdata, self.cdatasize),
                          pitch)
  return self
end

function Texture:_allocate_data()
  local npixels = self.width * self.height
                * (self.depth or 1)
                * (self.array_count or 1)
  log.debug("Allocating texture data for " .. npixels .. " pixels.")
  local nchannels = self.format.n_channels
  local datatype = self.format.channel_type
  self.cdatasize = self.format.channel_size * npixels * nchannels
  self.cdata = terralib.new(datatype[npixels * nchannels])
end

function Texture:_create_handle_bgfx()
  local bmem = self._bmem or bgfx.copy(self.cdata, self.cdatasize)
  local info = terralib.new(bgfx.texture_info_t)
  self._handle = bgfx.create_texture(bmem, self._cflags, 0, info)
end

function Texture2d:_create_handle()
  local bmem = nil
  if (not self.dynamic) and (self._bmem or self.cdata) then
    bmem = self._bmem or bgfx.make_ref(self.cdata, self.cdatasize)
  end
  self._handle = bgfx.create_texture_2d(self.width, self.height, 
                        self.has_mips or false, self.array_count or 1,
                        self.format.bgfx_enum, self._cflags, bmem)
  self._bmem = nil
end

function TextureCube:_create_handle()
  local bmem = nil
  if (not self.dynamic) and (self._bmem or self.cdata) then
    bmem = self._bmem or bgfx.make_ref(self.cdata, self.cdatasize)
  end
  self._handle = bgfx.create_texture_cube(self.width, self.has_mips or false,
                        self.array_count or 1, self.format.bgfx_enum, 
                        self._cflags, bmem)
  self._bmem = nil
end

function Texture3d:_create_handle()
  local bmem = nil
  if (not self.dynamic) and (self._bmem or self.cdata) then
    bmem = self._bmem or bgfx.make_ref(self.cdata, self.cdatasize)
  end
  self._handle = bgfx.create_texture_3d(self.width, self.height, self.depth, 
                   self.has_mips or false, self.format.bgfx_enum, 
                   self._cflags, bmem)
  self._bmem = nil
end

local default_tex_flags = {
  u = "repeat", v = "repeat", w = "repeat",
  min = "bilinear", mag = "bilinear",
  mip = false, msaa = false, rt = false, render_target = false,
  rt_msaa = false, rt_write_only = false,
  compare = false, compute_write = false,
  srgb = false, blit_dest = false, read_back = false
}

-- bgfx doesn't actually define constants for default texture
-- states, e.g., repeat and bilinear filtering
-- also define some aliases
local bgfx_tex_overrides = {
  TEXTURE_U_REPEAT = 0,
  TEXTURE_V_REPEAT = 0,
  TEXTURE_W_REPEAT = 0,
  TEXTURE_MIN_BILINEAR = 0,
  TEXTURE_MAG_BILINEAR = 0,
  TEXTURE_BLIT_DEST = bgfx.TEXTURE_BLIT_DST,
  TEXTURE_RENDER_TARGET = bgfx.TEXTURE_RT
}

function m.combine_tex_flags(_options)
  local state = bgfx.TEXTURE_NONE
  local options = {}
  truss.extend_table(options, default_tex_flags)
  truss.extend_table(options, _options or {})

  for k, v in pairs(options) do
    if default_tex_flags[k] == nil then
      truss.error("Unknown texture flag " .. k)
    end

    local const_name = "TEXTURE_" .. string.upper(k)
    if v then
      if v ~= true then
        const_name = const_name .. "_" .. string.upper(v)
      end
      local sval = bgfx_tex_overrides[const_name] or bgfx[const_name]
      if not sval then truss.error("No flag " .. const_name) end
      state = math.ullor(state, sval)
    end
  end

  return state, options
end

local nvg_utils = truss.addons.nanovg.functions
local nvg_pointer = truss.addons.nanovg.pointer

local function texture_from_handle(handle, info, flags)
  local ret = nil
  if info.cubeMap then
    ret = TextureCube()
  elseif info.depth > 1 then
    ret = Texture3d()
  else
    ret = Texture2d()
  end
  ret:_raw_set_handle(handle, info)
  ret:_raw_set_flags(flags)
  return ret
end

local function load_texture_image(filename, flags)
  local w = terralib.new(int32[2])
  local h = terralib.new(int32[2])
  local n = terralib.new(int32[2])
  local msg = nvg_utils.truss_nanovg_load_image(nvg_pointer, filename, w, h, n)
  if msg == nil then truss.error("Texture load error: " .. filename) end
  local bmem = bgfx.copy(msg.data, msg.data_length)
  truss.C.release_message(msg)
  local ret = Texture2d{width = w[0], height = h[0], format = fmt.TEX_RGBA8,
                        flags = flags, allocate = false, commit = false}
  ret._bmem = bmem
  ret:commit()
  return ret
end

local function load_texture_bgfx(filename, flags)
  local msg = truss.C.load_file(filename)
  if msg == nil then truss.error("Texture load error: " .. filename) end
  local bmem = bgfx.copy(msg.data, msg.data_length)
  truss.C.release_message(msg)
  local info = terralib.new(bgfx.texture_info_t)
  local cflags, flags = m.combine_tex_flags(flags or {})
  local handle = bgfx.create_texture(bmem, cflags, 0, info)
  return texture_from_handle(handle, info, flags)
end

local texture_loaders = {
  [".png"] = load_texture_image,
  [".jpg"] = load_texture_image,
  [".ktx"] = load_texture_bgfx,
  [".dds"] = load_texture_bgfx,
  [".pvr"] = load_texture_bgfx
}

function m.Texture(filename, flags)
  local extension = string.lower(string.sub(filename, -4, -1))
  local loader = texture_loaders[extension]
  if not loader then truss.error("No texture loader for " .. extension) end
  return loader(filename, flags)
end

-- load just the raw pixel data of a texture
function m.load_texture_data(fn)
  local w = terralib.new(int32[2])
  local h = terralib.new(int32[2])
  local n = terralib.new(int32[2])
  local msg = nvg_utils.truss_nanovg_load_image(nvg_pointer, fn, w, h, n)
  if w[0] <= 0 or h[0] <= 0 or n[0] <= 0 then
    log.error("tex load error: " .. w[0] .. " " .. h[0] .. " " .. n[0])
    truss.C.release_message(msg)
    return nil
  end
  local dsize = w[0]*h[0]*n[0]
  local ndata = terralib.new(uint8[w[0]*h[0]*n[0]])
  for i = 0, dsize - 1 do
    ndata[i] = msg.data[i]
  end
  truss.C.release_message(msg)
  return {w = w[0], h = h[0], n = n[0], data = ndata}
end

return m
