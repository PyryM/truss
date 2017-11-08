-- rendertarget.t
--
-- a class for abstracting the bgfx render buffers

local math = require("math")
local class = require("class")

local m = {}
local RenderTarget = class("RenderTarget")
m.RenderTarget = RenderTarget

m.color_formats = {
  default   = bgfx.TEXTURE_FORMAT_BGRA8,
  BGRA8     = bgfx.TEXTURE_FORMAT_BGRA8,
  RGBA8     = bgfx.TEXTURE_FORMAT_RGBA8,
  UINT8     = bgfx.TEXTURE_FORMAT_BGRA8,
  HALFFLOAT = bgfx.TEXTURE_FORMAT_RGBA16F,
  FLOAT     = bgfx.TEXTURE_FORMAT_RGBA32F
}

m.color_format_sizes = {
  [bgfx.TEXTURE_FORMAT_BGRA8] = 4,
  [bgfx.TEXTURE_FORMAT_RGBA8] = 4,
  [bgfx.TEXTURE_FORMAT_RGBA16F] = 8,
  [bgfx.TEXTURE_FORMAT_RGBA32F] = 16
}

function RenderTarget:init(width, height)
  self.width = width
  self.height = height
  self.attachments = {}
  self._construction_args = {}
end

function RenderTarget:make_RGB(color_format, depth_bits, has_stencil)
  if depth_bits == true or depth_bits == nil then depth_bits = 24 end
  if depth_bits == false then depth_bits = 0 end
  local has_depth = depth_bits > 0
  self:add_color_attachment(color_format)
  if has_depth then
    log.debug("Creating render target with depth buffer.")
    self:add_depth_attachment(depth_bits, has_stencil)
  end
  self:finalize()
  return self
end

function RenderTarget:make_RGB8(depth_bits, has_stencil)
  return self:make_RGB(m.color_formats.BGRA8, depth_bits, has_stencil)
  --return self:make_RGB(m.color_formats.RGBA8, depth_bits, has_stencil)
end

function RenderTarget:make_RGBF(depth_bits, has_stencil)
  return self:make_RGB(m.color_formats.FLOAT, depth_bits, has_stencil)
end

function RenderTarget:make_shadow(shadowbits, has_stencil)
  shadowbits = shadowbits or 16
  self:add_shadow_attachment(shadowbits, has_stencil)
  self:finalize()
  return self
end

function RenderTarget:make_gbuffer(color_formats, depth_bits, has_stencil)
  if depth_bits == true or depth_bits == nil then depth_bits = 24 end
  if depth_bits == false then depth_bits = 0 end
  local has_depth = depth_bits > 0
  for _, color_format in ipairs(color_formats) do
    self:add_color_attachment(color_format)
  end
  if has_depth then
    log.debug("Creating render target with depth buffer.")
    self:add_depth_attachment(depth_bits, has_stencil)
  end
  self:finalize()
  return self
end

function RenderTarget:make_backbuffer()
  if self.finalized then
    log.error("Cannot convert finalized rendertarget to backbuffer!")
    return
  end
  local gfx = require("gfx")
  self.width, self.height = gfx.backbuffer_width, gfx.backbuffer_height
  self.is_backbuffer = true
  self.has_color = true
  self.has_depth = true
  self.framebuffer = gfx.invalid_handle(bgfx.frame_buffer_handle_t)
  self.finalized = true
  return self
end

function RenderTarget:_validate_tex_size(tex)
  if (not tex) or (not tex._info) then truss.error("nil tex or no info") end
  local tw, th = tex._info.width, tex._info.height
  if tw == nil or th == nil then truss.error("nil tex height or width") end
  if self.width == nil or self.height == nil then
    self.width, self.height = tw, th
  else
    if self.width ~= tw or self.height ~= th then
      truss.error("RT/Texture size mismatch")
    end
  end
end

function RenderTarget:from_texture(tex, mip, layer, depth_bits, has_stencil)
  self:_validate_tex_size(tex)
  if depth_bits == true or depth_bits == nil then depth_bits = 24 end
  if depth_bits == false then depth_bits = 0 end
  self:add_texture_attachment(tex, mip, layer)
  if depth_bits > 0 then
    self:add_depth_attachment(depth_bits, has_stencil)
  end
  self:finalize()
  return self
end

-- need a function that always returns 6 arguments because regular unpack won't
-- work with embedded nils, and terra/ffi bound functions expect an exact number
-- of arguments
local function unpack7(v)
  return v[1],v[2],v[3],v[4],v[5],v[6],v[7]
end

function RenderTarget:add_color_attachment(color_format, flags)
  if self.finalized then
    log.error("Cannot add more attachments to finalized buffer!")
    return
  end
  local color_flags = flags or math.combine_flags(bgfx.TEXTURE_RT,
                     bgfx.TEXTURE_U_CLAMP,
                     bgfx.TEXTURE_V_CLAMP)
  local tex_args = {self.width, self.height, false, 1,
                   color_format or m.color_formats.default, color_flags, nil}
  local handle = bgfx.create_texture_2d(unpack7(tex_args))
  table.insert(self.attachments, {handle = handle})
  table.insert(self._construction_args, tex_args)
  self.has_color = true
  return self
end

function RenderTarget:add_texture_attachment(tex, mip, layer)
  if not tex._render_target then truss.error("Provided texture not renderable") end
  local handle = tex._handle
  if not handle then truss.error("Provided texture has no handle") end
  table.insert(self.attachments, {handle = handle, mip = mip, layer = layer})
  self.has_color = true
  self._cloneable = false
  self._external_textures = true
end

function RenderTarget:add_depth_attachment(depth_bits, has_stencil, flags, is_float)
  if self.finalized then
    log.error("Cannot add more attachments to finalized buffer!")
    return
  end
  local fmt_name = "TEXTURE_FORMAT_" .. "D" .. depth_bits
  if is_float then fmt_name = fmt_name .. "F" end
  if has_stencil then fmt_name = fmt_name .. "S8" end
  log.debug("RenderTarget using depth format " .. fmt_name)
  local depth_format = bgfx[fmt_name]
  if not depth_format then
    log.error("Depth format " .. fmt_name .. " does not exist.")
    return
  end
  local tex_args = {self.width, self.height, false, 1,
                   depth_format, flags or bgfx.TEXTURE_RT_WRITE_ONLY, nil}
  local handle = bgfx.create_texture_2d(unpack7(tex_args))
  table.insert(self.attachments, {handle = handle})
  table.insert(self._construction_args, tex_args)
  self.has_depth = true
  return self
end

function RenderTarget:add_shadow_attachment(depth_bits, has_stencil)
  -- basically the same as a regular depth stencil attachment, except with
  -- slightly different flags to allow it to be used in a shadow sampler
  local flags = math.combine_flags(bgfx.TEXTURE_RT, bgfx.TEXTURE_COMPARE_LEQUAL)
  return self:add_depth_attachment(depth_bits, has_stencil, flags, true)
end

function RenderTarget:finalize()
  local attachments = self.attachments
  local cattachments = terralib.new(bgfx.attachment_t[#attachments])
  for i,v in ipairs(attachments) do
    cattachments[i-1].handle = v.handle -- ffi cstructs are zero indexed
    cattachments[i-1].mip = v.mip or 0
    cattachments[i-1].layer = v.layer or 0
  end
  -- if used as the value of a texture uniform, use first attachment
  self.raw_tex = self.attachments[1].handle
  local destroy_textures = not not self._external_textures
  self.framebuffer = bgfx.create_frame_buffer_from_attachment(#attachments,
                            cattachments, destroy_textures)
  self.cattachments = cattachments
  self.finalized = true
  return self
end

function RenderTarget:_construct(conargs)
  self._construction_args = {}
  for i,curarg in ipairs(conargs) do
    local handle = bgfx.create_texture_2d(unpack7(curarg))
    table.insert(self.attachments, {handle = handle})
    table.insert(self._construction_args, curarg)
  end
end

-- create a new rendertarget with the same layout as this one
-- does NOT copy the contents of the rendertarget
function RenderTarget:clone(finalize)
  if self._cloneable == false then
    truss.error("RenderTarget is not cloneable.")
  end
  local ret = RenderTarget(self.width, self.height)
  ret.has_color = self.has_color
  ret.has_depth = self.has_depth
  ret.is_backbuffer = self.is_backbuffer
  ret:_construct(self._construction_args)
  if finalize ~= false then ret:finalize() end
  return ret
end

-- create a texture that can be blitted into and a buffer to hold the data
function RenderTarget:create_read_back_buffer(idx)
  log.debug("Creating readbuffer for attachment " .. idx)
  local ainfo = self._construction_args[idx]

  local w, h, fmt = ainfo[1], ainfo[2], ainfo[4]
  local pixelsize = m.color_format_sizes[fmt]
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
  if self._readbuffers == nil then self._readbuffers = {} end
  if self._readbuffers[idx] == nil then
    self._readbuffers[idx] = self:create_read_back_buffer(idx)
  end
  return self._readbuffers[idx]
end

function RenderTarget:destroy()
  -- TODO: maybe this should use gfx.schedule to avoid the
  -- possibility of destroying this framebuffer when it's 
  -- already been used in a submit this frame
  if self.framebuffer then
    bgfx.destroy_frame_buffer(self.framebuffer)
  end
  self.framebuffer = nil
  self.attachments = nil
  self.cattachments = nil
  self.finalized = false
  self.raw_tex = nil
end

return m
