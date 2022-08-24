-- gfx/texture.t
--
-- textures

local class = require("class")
local math = require("math")
local fmt = require("./formats.t")
local bgfx = require("./bgfx.t")
local gfx_common = require("./common.t")

local m = {}

local Texture = class("Texture")
local Texture2d = Texture:extend("Texture2d")
local Texture3d = Texture:extend("Texture3d")
local TextureCube = Texture:extend("TextureCube")

m.Texture2d = Texture2d
m.TextureCube = TextureCube
m.Texture3d = Texture3d

function Texture:init(options)
  self:_raw_set_flags(options.flags, options.sampler_flags)
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

function Texture:is_possible()
  local format = self.format
  if type(format) == 'table' then format = format.bgfx_enum end
  return bgfx.is_texture_valid(
    self.depth or 1, 
    self:is_cubemap(), 
    1, -- layers
    format,   
    self._cflags or 0)
end

function Texture:_assert_possible()
  if not self:is_possible() then
    local errstr = ("Tex cfg invalid: d:%d, cm:%s, fmt:%s, flags:%s"):format(
      self.depth or 1, tostring(self:is_cubemap()), self.format.name,
      m.print_tex_flags(self.flags or {}))
    truss.error(errstr)
  end
end

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

function Texture:_raw_set_flags(flags, sampler_flags)
  self._cflags, self.flags = m.combine_tex_flags(flags or {}, "TEXTURE_")
  self._cflags = math.ullor(
    self._cflags, (m.combine_tex_flags(sampler_flags or {}, "SAMPLER_"))
  )
end

function Texture:is_renderable()
  local f = self.flags
  return f.render_target or f.rt_msaa or f.rt_write_only
end

function Texture:is_blittable()
  return self.flags.blit_dest
end

function Texture:is_readable()
  return self.flags.read_back
end

function Texture:is_cubemap()
  return not not self._is_cubemap
end

function Texture:is_compute_writeable()
  return self.flags.compute_write
end

function Texture:raw_blit_copy(src_handle, view)
  if not self._handle then
    truss.error("No texture handle!")
  end
  if not self:is_blittable() then
    truss.error("Texture not a blit_dest!")
  end
  if type(src_handle) == 'table' then
    src_handle = assert(src_handle._handle)
  end
  local viewid = view or 0
  if type(viewid) == 'table' then
    viewid = view._viewid or 0
  end
  bgfx.blit(viewid,
        self._handle, 0, 0, 0, 0,
        src_handle, 0, 0, 0, 0,
        self.width, self.height, self.depth)
end

function Texture:read_back(mip, callback)
  if not self._handle then
    truss.error("No texture handle!")
  end
  if not self:is_readable() then 
    truss.error("Texture does not have read_back flag.")
  end
  if not self.cdata then
    truss.error("Texture does not have buffer to read back into!")
  end
  bgfx.read_texture(self._handle, self.cdata, mip or 0)
  if callback then
    require("gfx").schedule(callback)
  end
end

function Texture:async_read_back(mip)
  local async = require("async")
  local p = async.Promise()
  self:read_back(mip, function()
    p:resolve(self)
  end)
  return p
end

function Texture:async_read_rt(view, mip)
  local rt = self.read_source.rt
  local layer = self.read_source.layer
  self:raw_blit_copy(rt:get_layer_handle(layer), view or 255)
  return self:async_read_back(mip or 0)
end

function Texture:bind_compute(stage, mip, access, format)
  access = gfx_common.resolve_access(access)
  format = format or self.format
  if type(format) == 'table' then format = format.bgfx_enum end
  bgfx.set_image(stage, self._handle, mip or 0, access, format or bgfx.TEXTURE_FORMAT_COUNT)
end

function Texture:_raw_set_handle(handle, info)
  self._handle = handle
  self.width = info.width
  self.height = info.height
  self.depth = info.depth
  self.has_mips = info.numMips > 0
  self.array_count = info.numLayers
  self._is_cubemap = info.cubeMap
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
  self._is_cubemap = true
  self:_set_or_create_data(options)
end

function Texture:commit()
  if self._handle then
    truss.error("Cannot commit texture twice.")
  end
  log.debug("Committing texture.")
  self:_assert_possible()
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
  self.cdatalen = npixels * nchannels
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
  SAMPLER_ = {
    u = "repeat", v = "repeat", w = "repeat",
    min = "bilinear", mag = "bilinear", mip = false,
    compare = false
  },
  TEXTURE_ = {
    msaa = false, rt = false, render_target = false,
    rt_msaa = false, rt_write_only = false, srgb = false, msaa_sample = false,
    compute_write = false, rgb = false, blit_dest = false, read_back = false
  }
}

-- bgfx doesn't actually define constants for default texture
-- states, e.g., repeat and bilinear filtering
-- also define some aliases
local bgfx_tex_overrides = {
  SAMPLER_U_REPEAT = 0,
  SAMPLER_V_REPEAT = 0,
  SAMPLER_W_REPEAT = 0,
  SAMPLER_MIN_BILINEAR = 0,
  SAMPLER_MAG_BILINEAR = 0,
  TEXTURE_BLIT_DEST = bgfx.TEXTURE_BLIT_DST,
  TEXTURE_RENDER_TARGET = bgfx.TEXTURE_RT
}

function m.combine_tex_flags(_options, prefix)
  prefix = prefix or "TEXTURE_"
  local state = bgfx[prefix .. "NONE"] -- e.g. TEXTURE_NONE
  local options = {}
  truss.extend_table(options, default_tex_flags[prefix])
  truss.extend_table(options, _options or {})

  for k, v in pairs(options) do
    local const_name = prefix .. string.upper(k)
    if default_tex_flags[prefix][k] == nil then
      truss.error("Invalid texture flag '" .. k .. "' -> " .. const_name)
    end

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

function m.print_tex_flags(flags)
  local frags = {}
  for k, v in pairs(flags) do
    table.insert(frags, ("%s: %s"):format(k, tostring(v)))
  end
  return table.concat(frags, ",")
end

local function texture_from_handle(handle, info, flags, sampler_flags)
  local ret = nil
  if info.cubeMap then
    ret = TextureCube()
  elseif info.depth > 1 then
    ret = Texture3d()
  else
    ret = Texture2d()
  end
  ret:_raw_set_handle(handle, info)
  ret:_raw_set_flags(flags, sampler_flags)
  return ret
end

local function load_texture_image(filename, flags, sampler_flags)
  local imageload = require("./imageload.t")
  local img = imageload.load_image_from_file(filename)
  if img == nil then truss.error("Texture load error: " .. filename) end
  local bmem = bgfx.copy(img.data, img.datasize)
  local ret = Texture2d{width = img.width, height = img.height, format = fmt.TEX_RGBA8,
                        flags = flags, sampler_flags = sampler_flags,
                        allocate = false, commit = false}
  ret._bmem = bmem
  ret:commit()
  imageload.release_image(img)
  return ret
end

local function load_texture_bgfx(filename, flags, sampler_flags)
  local msg = truss.read_file_buffer(filename)
  if not msg then error("Texture load error: " .. filename) end
  local bmem = bgfx.copy(msg.data, msg.size)
  local info = terralib.new(bgfx.texture_info_t)
  local cflags, flags = m.combine_tex_flags(flags or {}, "TEXTURE_")
  local scflags, sflags = m.combine_tex_flags(sampler_flags or {}, "SAMPLER_")
  cflags = math.ullor(cflags, scflags)
  local handle = bgfx.create_texture(bmem, cflags, 0, info)
  return texture_from_handle(handle, info, flags, sampler_flags)
end

local texture_loaders = {
  [".png"] = load_texture_image,
  [".jpg"] = load_texture_image,
  [".ktx"] = load_texture_bgfx,
  [".dds"] = load_texture_bgfx,
  [".pvr"] = load_texture_bgfx
}

function m.Texture(filename, flags, sampler_flags)
  local extension = string.lower(string.sub(filename, -4, -1))
  local loader = texture_loaders[extension]
  if not loader then truss.error("No texture loader for " .. extension) end
  return loader(filename, flags, sampler_flags)
end

function m.ReadbackTexture(src, layer)
  layer = layer or 1 
  local info = src:get_layer_info(layer)
  local flags = {
    blit_dest = true, read_back = true
  }
  local sampler_flags = {
    min = 'point', mag = 'point', mip = 'point',
    u = 'clamp', v = 'clamp'
  }
  local tex = m.Texture2d{
    allocate = true, flags = flags, sampler_flags = sampler_flags,
    width = info.width, height = info.height,
    format = info.format
  }
  tex.read_source = {rt = src, layer = layer}
  return tex:commit()
end

return m
