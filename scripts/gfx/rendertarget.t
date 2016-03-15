-- rendertarget.t
--
-- a class for abstracting the bgfx render buffers

local class = require("class")

local m = {}
local RenderTarget = class("RenderTarget")

function RenderTarget:init(width, height, hasDepth)
    local bc = bgfx_const
    local flags = bc.BGFX_TEXTURE_RT + 
                  bc.BGFX_TEXTURE_U_CLAMP + 
                  bc.BGFX_TEXTURE_V_CLAMP

    local color = bgfx.bgfx_create_texture_2d(width, height, 1, 
                        bgfx.BGFX_TEXTURE_FORMAT_BGRA8, flags, nil)

    local attachments = terralib.new(bgfx.bgfx_texture_handle_t[2])
    attachments[0] = color
    numAttachments = 1

    if hasDepth then
        local depthflags = bc.BGFX_TEXTURE_RT_WRITE_ONLY
        local depth = bgfx.bgfx_create_texture_2d(width, height, 1, 
                            bgfx.BGFX_TEXTURE_FORMAT_D16, depthflags, nil)

        attachments[1] = depth
        numAttachments = 2
    end

    self.frameBuffer = bgfx.bgfx_create_frame_buffer_from_handles(numAttachments, attachments, true)
    self.attachments = attachments
end

function RenderTarget:destroy()
    if self.frameBuffer then
        bgfx.bgfx_destroy_frame_buffer(self.frameBuffer)
    end
    self.frameBuffer = nil
    self.attachments = nil
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