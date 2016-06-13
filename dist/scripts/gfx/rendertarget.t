-- rendertarget.t
--
-- a class for abstracting the bgfx render buffers

local math = require("math")
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

function RenderTarget:makeRGB8(depthBits, hasStencil)
    if depthBits == true or depthBits == nil then depthBits = 24 end
    if depthBits == false then depthBits = 0 end
    local hasDepth = depthBits > 0
    self:addColorAttachment(m.ColorFormats.BGRA8)
    if hasDepth then
        log.debug("Creating render target with depth buffer.")
        self:addDepthStencilAttachment(depthBits, hasStencil)
    end
    self:finalize()
    return self
end

function RenderTarget:makeBackbuffer()
    if self.finalized then
        log.error("Cannot convert finalized rendertarget to backbuffer!")
        return
    end
    self.isBackbuffer = true
    self.hasColor = true
    self.hasDepth = true
    self.frameBuffer = nil
    self.finalized = true
    return self
end

local bc = bgfx_const
function RenderTarget:addColorAttachment(colorformat)
    if self.finalized then
        log.error("Cannot add more attachments to finalized buffer!")
        return
    end
    local colorflags = bc.BGFX_TEXTURE_RT +
                       bc.BGFX_TEXTURE_U_CLAMP +
                       bc.BGFX_TEXTURE_V_CLAMP
    local color = bgfx.bgfx_create_texture_2d(self.width, self.height, 1,
                        colorformat or m.ColorFormats.default,
                        colorflags, nil)
    table.insert(self.attachments, color)
    self.hasColor = true
    return self
end

function RenderTarget:addDepthStencilAttachment(depthBits, hasStencil)
    if self.finalized then
        log.error("Cannot add more attachments to finalized buffer!")
        return
    end
    local fmtName = "BGFX_TEXTURE_FORMAT_" .. "D" .. depthBits
    if hasStencil then fmtName = fmtName .. "S8" end
    log.debug("RenderTarget using depth format " .. fmtName)
    local depthFormat = bgfx[fmtName]
    if not depthFormat then
        log.error("Depth format " .. fmtName .. " does not exist.")
        return
    end
    local depth = bgfx.bgfx_create_texture_2d(self.width, self.height, 1,
                        depthFormat, bc.BGFX_TEXTURE_RT_WRITE_ONLY, nil)
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
    self.finalized = false
end

function RenderTarget:setViewClear(viewid, clearValues)
    local clearColor = clearValues.color or 0x000000ff
    local clearDepth = clearValues.depth or 1.0
    local clearStencil = clearValues.stencil
    local clearFlags = bgfx_const.BGFX_CLEAR_NONE

    if clearValues.color ~= false and self.hasColor then
        clearFlags = math.ullor(clearFlags, bgfx_const.BGFX_CLEAR_COLOR)
    end
    if clearValues.depth ~= false and self.hasDepth then
        clearFlags = math.ullor(clearFlags, bgfx_const.BGFX_CLEAR_DEPTH)
    end
    if clearStencil then
        clearFlags = math.ullor(clearFlags, bgfx_const.BGFX_CLEAR_STENCIL)
    end

    bgfx.bgfx_set_view_clear(viewid, clearFlags,
                             clearColor, clearDepth, clearStencil or 0)
end

function RenderTarget:bindToView(viewid, setViewRect)
    if self.frameBuffer or self.isBackbuffer then
        self.viewid = viewid
        if self.frameBuffer then
            bgfx.bgfx_set_view_frame_buffer(viewid, self.frameBuffer)
        end
        if setViewRect == nil or setViewRect then -- default to true
            bgfx.bgfx_set_view_rect(viewid, 0, 0, self.width, self.height)
        end
    else
        log.error("Cannot bind null framebuffer to view!")
    end
end

m.RenderTarget = RenderTarget
return m
