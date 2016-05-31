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
    self.hasColor = true
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
    self.hasDepth = true
    return self
end

function RenderTarget:finalize()
    local attachments = self.attachments
    local cattachments = terralib.new(bgfx.bgfx_attachment_t[#attachments])
    for i,v in ipairs(attachments) do
        cattachments[i-1].handle = v -- ffi cstructs are zero indexed
        cattachments[i-1].mip = 0
        cattachments[i-1].layer = 0
    end
    self.frameBuffer = bgfx.bgfx_create_frame_buffer_from_attachment(#attachments, cattachments, true)
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

function RenderTarget:setViewClear(viewid, clearValues)
    local clearColor = clearValues.color or 0x303030ff
    local clearDepth = clearValues.depth or 1.0
    local clearStencil = clearValues.stencil
    local clearFlags = bgfx_const.BGFX_CLEAR_NONE

    if clearValues.color ~= false and self.hasColor then
        clearFlags = bit.bor(clearFlags, bgfx_const.BGFX_CLEAR_COLOR)
    end
    if clearValues.depth ~= false and self.hasDepth then
        clearFlags = bit.bor(clearFlags, bgfx_const.BGFX_CLEAR_DEPTH)
    end
    if clearStencil then
        clearFlags = bit.bor(clearFlags, bgfx_const.BGFX_CLEAR_STENCIL)
    end

    bgfx.bgfx_set_view_clear(viewid, clearFlags,
                             clearColor, clearDepth, clearStencil or 0)
end

function RenderTarget:bindToView(viewid, setViewRect)
    if self.frameBuffer then
        self.viewid = viewid
        bgfx.bgfx_set_view_frame_buffer(viewid, self.frameBuffer)
        if setViewRect == nil or setViewRect then -- default to true
            bgfx.bgfx_set_view_rect(viewid, 0, 0, self.width, self.height)
        end
    else
        log.error("Cannot bind null framebuffer to view!")
    end
end

m.RenderTarget = RenderTarget
return m
