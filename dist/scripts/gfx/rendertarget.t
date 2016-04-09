-- rendertarget.t
--
-- a class for abstracting the bgfx render buffers

local class = require("class")

local m = {}
local RenderTarget = class("RenderTarget")

m.ColorFormats = {
    default   = bgfx.BGFX_TEXTURE_FORMAT_BGRA8,
    BGRA8     = bgfx.BGFX_TEXTURE_FORMAT_BGRA8,
    UINT8     = bgfx.BGFX_TEXTURE_FORMAT_BGRA8,
    HALFFLOAT = bgfx.BGFX_TEXTURE_FORMAT_RGBA16F,
    FLOAT     = bgfx.BGFX_TEXTURE_FORMAT_RGBA32F
}

function RenderTarget:init(width, height)
    self.width = width
    self.height = height
    self.attachments = {}
end

function RenderTarget:makeRGB8(hasDepth)
    hasDepth = (hasDepth == nil) or hasDepth
    self:addColorAttachment(self.width, self.height, m.ColorFormats.BGRA8)
    if hasDepth then
        log.debug("Creating render target with depth buffer.")
        self:addDepthAttachment(self.width, self.height)
    end
    self:finalize()
    return self
end

local bc = bgfx_const
function RenderTarget:addColorAttachment(width, height, colorformat)
    if self.finalized then
        log.error("Cannot add more attachments to finalized buffer!") 
        return 
    end
    local colorflags = bc.BGFX_TEXTURE_RT + 
                       bc.BGFX_TEXTURE_U_CLAMP + 
                       bc.BGFX_TEXTURE_V_CLAMP
    local color = bgfx.bgfx_create_texture_2d(width, height, 1, 
                        colorformat or m.ColorFormats.default, 
                        colorflags, nil)
    table.insert(self.attachments, color)
    return self
end

function RenderTarget:addDepthAttachment(width, height)
    if self.finalized then 
        log.error("Cannot add more attachments to finalized buffer!")
        return 
    end
    local depthflags = bc.BGFX_TEXTURE_RT_WRITE_ONLY -- can't read back depth
    local depth = bgfx.bgfx_create_texture_2d(width, height, 1, 
                        bgfx.BGFX_TEXTURE_FORMAT_D16, depthflags, nil)
    table.insert(self.attachments, depth)
    return self
end

function RenderTarget:finalize()
    local attachments = self.attachments
    local cattachments = terralib.new(bgfx.bgfx_texture_handle_t[#attachments])
    for i,v in ipairs(attachments) do
        cattachments[i-1] = v -- ffi cstructs are zero indexed
    end
    self.frameBuffer = bgfx.bgfx_create_frame_buffer_from_handles(#attachments, cattachments, true)
    self.cattachments = cattachments
    self.finalized = true
    return self
end

function RenderTarget:destroy()
    if self.frameBuffer then
        bgfx.bgfx_destroy_frame_buffer(self.frameBuffer)
    end
    self.frameBuffer = nil
    self.attachments = nil
    self.cattachments = nil
end

function RenderTarget:bindToView(viewid)
    if self.frameBuffer then
        bgfx.bgfx_set_view_frame_buffer(viewid, self.frameBuffer)
    else
        log.error("Cannot bind null framebuffer to view!")
    end
end

m.RenderTarget = RenderTarget
return m