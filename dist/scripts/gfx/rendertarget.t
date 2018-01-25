-- rendertarget.t
--
-- a class for abstracting the bgfx render buffers

local math = require("math")
local class = require("class")
local fmt = require("gfx/formats.t")

local m = {}
local RenderTarget = class("RenderTarget")
m.RenderTarget = RenderTarget

local function depth_stencil_layer(format, flags, shadow)
  log.debug("adding depth/stencil layer " .. format.name)
  flags = flags or bgfx.TEXTURE_RT_WRITE_ONLY
  if shadow then
    flags = math.combine_flags(flags, bgfx.TEXTURE_COMPARE_LEQUAL)
  end
  return {
    has_mips = false, -- can depth buffers even have mips?
    flags = flags,
    format = format,
    has_depth = true,
    has_stencil = format.has_stencil
  }
end

local function color_layer(format, flags, has_mips)
  log.debug("adding color layer " .. format.name)
  local flags = flags or math.combine_flags(bgfx.TEXTURE_RT,
                                            bgfx.TEXTURE_U_CLAMP,
                                            bgfx.TEXTURE_V_CLAMP)
  return {
    has_mips = has_mips, 
    flags = flags,
    format = format,
    has_color = true
  }
end

function m.ColorDepthTarget(options)
  options = options or {}
  local color_format = options.color_format
  local depth_format = options.depth_format
  if color_format == nil then
    color_format = fmt.TEX_BGRA8
  end
  if depth_format == nil then
    depth_format = fmt.TEX_D24S8
  end
  local layers = {color_layer(color_format, options.color_flags, options.mips)}
  if depth_format then
    layers[2] = depth_stencil_layer(depth_format, options.depth_flags, false)
  end
  return RenderTarget{
    width = options.width, height = options.height, layers = layers
  }
end

function m.GBufferTarget(options)
  local layers = {}
  local color_flags = options.color_flags
  local mips = options.mips
  for _, format in ipairs(options.color_formats) do
    table.insert(layers, color_layer(format, color_flags, mips))
  end
  if options.depth_format then
    table.insert(layers, depth_stencil_layer(options.depth_format, 
                                             options.depth_flags, false))
  end
  return RenderTarget{
    width = options.width, height = options.height, layers = layers
  }
end

function m.BackbufferTarget()
  return RenderTarget{backbuffer = true}
end

function m.TextureTarget(options)
  local tex = options.texture or options.tex
  if not tex._render_target then truss.error("Provided texture not renderable") end
  local handle = tex._handle
  if not handle then truss.error("Provided texture has no handle") end
  local layers = {{handle = handle, 
                   mip = options.mip, 
                   layer = options.layer,
                   has_color = true}}

  if options.depth_format then
    table.insert(layers, depth_stencil_layer(options.depth_format, 
                                             options.depth_flags, false))
  end

  return RenderTarget{
    width = tex._info.width, 
    height = tex._info.height, 
    layers = layers
  }
end

------------------------------------------------------------------------------
-- RenderTarget
--
-- The actual rendertarget class; usually you shouldn't try to instantiate 
-- this directly, but instead should use one of the above factory methods.
------------------------------------------------------------------------------

function RenderTarget:init(options)
  if type(options) == "number" then
    truss.error("RenderTarget no longer takes (w,h) as arguments.")
  end
  if options.backbuffer then
    local gfx = require("gfx")
    self.is_backbuffer = true
    self.has_color = true
    self.has_depth = true
    self.width = gfx.backbuffer_width
    self.height = gfx.backbuffer_height
    self.framebuffer = gfx.invalid_handle(bgfx.frame_buffer_handle_t)
  else
    if not (options.width and options.height) then
      truss.error("RenderTarget(): width and height must be specified")
    end
    self.width = options.width
    self.height = options.height
    self:_construct(options.layers)
  end
end

function RenderTarget:_construct(layers)
  self.has_color = false
  self.has_depth = false
  self.has_stencil = false
  self.is_backbuffer = false
  self.cloneable = true
  self._layers = {}
  self._owned_textures = {}

  local cattachments = terralib.new(bgfx.attachment_t[#layers])
  self.attachments = {}
  for i, layer in ipairs(layers) do
    local handle = nil
    if layer.handle then
      handle = layer.handle
      self.cloneable = false
    elseif layer.format then
      local has_mips = layer.has_mips or false
      local array_count = 1 -- can't render to texture arrays afik
      handle = bgfx.create_texture_2d(self.width, self.height, has_mips,
                                      array_count, layer.format.bgfx_enum, 
                                      layer.flags, nil)
      table.insert(self._owned_textures, handle)
    else
      truss.error("RenderTarget layer has neither handle nor format")
    end
    table.insert(self.attachments, {handle = handle})
    table.insert(self._layers, layer)
    cattachments[i-1].handle = handle
    cattachments[i-1].mip = layer.mip or 0
    cattachments[i-1].layer = layer.layer or 0
    self.has_color = self.has_color or layer.has_color
    self.has_depth = self.has_depth or layer.has_depth
    self.has_stencil = self.has_stencil or layer.has_stencil
  end
  self._cattachments = cattachments
  self.raw_tex = self.attachments[1].handle
  -- don't have bgfx destroy textures: we'll handle that part by
  -- manually destroying handles in self._owned_textures
  self.framebuffer = bgfx.create_frame_buffer_from_attachment(#layers,
                            cattachments, false)
end

-- create a new rendertarget with the same layout as this one
-- does NOT copy the contents of the rendertarget
function RenderTarget:clone()
  if self.is_backbuffer then return self end -- there's just one backbuffer
  if not self.cloneable then
    truss.error("RenderTarget:clone: not backbuffer and not cloneable.")
  end
  local opts = {width = self.width, height = self.height, 
                layers = self._layers}
  return RenderTarget(opts)
end

function RenderTarget:get_attachment_handle(idx)
  return self.attachments[idx].handle
end

-- create a texture that can be blitted into and a buffer to hold the data
function RenderTarget:_create_read_back_buffer(idx)
  log.debug("Creating readbuffer for attachment " .. idx)
  local layer = self._layers[idx]
  if not layer.format then
    truss.error("RenderTarget attachment has no format information.")
  end

  local w, h = self.width, self.height
  local fmt = layer.format
  local pixelsize = fmt.pixel_size
  if not pixelsize then 
    truss.error("Format " .. fmt.name .. " has no pixel size; " 
                .. "(depth formats cannot be read back)")
  end
  local datasize = w*h*pixelsize

  local flags = math.combine_flags(
    --bgfx.TEXTURE_RT,
    bgfx.TEXTURE_BLIT_DST,
    bgfx.TEXTURE_READ_BACK,
    bgfx.TEXTURE_MIN_POINT,
    bgfx.TEXTURE_MAG_POINT,
    bgfx.TEXTURE_MIP_POINT,
    bgfx.TEXTURE_U_CLAMP,
    bgfx.TEXTURE_V_CLAMP )
  log.info("Flags: " .. tostring(flags))

  local dest = bgfx.create_texture_2d(w, h, false, 1, fmt, flags, nil)
  local buffer = truss.create_message(datasize)
  local src = self.attachments[idx].handle

  return {src = src, dest = dest, buffer = buffer}
end

-- convenience function to avoid repeatedly creating the same buffer
function RenderTarget:get_read_back_buffer(idx)
  if self.is_backbuffer then
    truss.error("Cannot create read back buffer for backbuffer.")
  end
  if self._readbuffers == nil then self._readbuffers = {} end
  if self._readbuffers[idx] == nil then
    self._readbuffers[idx] = self:_create_read_back_buffer(idx)
  end
  return self._readbuffers[idx]
end

function RenderTarget:destroy()
  if self.is_backbuffer then
    log.warning("Tried to destroy backbuffer.")
    return 
  end
  -- TODO: maybe this should use gfx.schedule to avoid the
  -- possibility of destroying this framebuffer when it's 
  -- already been used in a submit this frame
  if self.framebuffer then
    bgfx.destroy_frame_buffer(self.framebuffer)
  end
  for _, handle in ipairs(self._owned_textures or {}) do
    bgfx.destroy_texture(handle)
  end
  self._owned_textures = nil
  self.framebuffer = nil
  self.attachments = nil
  self._cattachments = nil
  self.raw_tex = nil
end

return m
