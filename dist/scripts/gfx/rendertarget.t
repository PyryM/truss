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
    self.constructionArgs_ = {}
end

function RenderTarget:makeRGB(colorFormat, depthBits, hasStencil)
    if depthBits == true or depthBits == nil then depthBits = 24 end
    if depthBits == false then depthBits = 0 end
    local hasDepth = depthBits > 0
    self:addColorAttachment(colorFormat)
    if hasDepth then
        log.debug("Creating render target with depth buffer.")
        self:addDepthStencilAttachment(depthBits, hasStencil)
    end
    self:finalize()
    return self
end

function RenderTarget:makeRGB8(depthBits, hasStencil)
    return self:makeRGB(m.ColorFormats.BGRA8, depthBits, hasStencil)
end

function RenderTarget:makeRGBF(depthBits, hasStencil)
    return self:makeRGB(m.ColorFormats.FLOAT, depthBits, hasStencil)
end

function RenderTarget:makeShadow(shadowbits, hasStencil)
    shadowbits = shadowbits or 16
    self:addShadowAttachment(shadowbits, hasStencil)
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

-- need a function that always returns 6 arguments because regular unpack won't
-- work with embedded nils, and terra/ffi bound functions expect an exact number
-- of arguments
local function unpack6(v)
    return v[1],v[2],v[3],v[4],v[5],v[6]
end

local bc = bgfx_const
function RenderTarget:addColorAttachment(colorformat, flags)
    if self.finalized then
        log.error("Cannot add more attachments to finalized buffer!")
        return
    end
    local colorflags = flags or math.combineFlags(bc.BGFX_TEXTURE_RT,
                       bc.BGFX_TEXTURE_U_CLAMP,
                       bc.BGFX_TEXTURE_V_CLAMP)
    local texArgs = {self.width, self.height, 1,
                     colorformat or m.ColorFormats.default, colorflags, nil}
    local color = bgfx.bgfx_create_texture_2d(unpack6(texArgs))
    table.insert(self.attachments, color)
    table.insert(self.constructionArgs_, texArgs)
    self.hasColor = true
    return self
end

function RenderTarget:addDepthStencilAttachment(depthBits, hasStencil, flags)
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
    local texArgs = {self.width, self.height, 1,
                     depthFormat, flags or bc.BGFX_TEXTURE_RT_WRITE_ONLY, nil}
    local depth = bgfx.bgfx_create_texture_2d(unpack6(texArgs))
    table.insert(self.attachments, depth)
    table.insert(self.constructionArgs_, texArgs)
    self.hasDepth = true
    return self
end

function RenderTarget:addShadowAttachment(depthBits, hasStencil)
    -- basically the same as a regular depth stencil attachment, except with
    -- slightly different flags to allow it to be used in a shadow sampler
    local flags = math.combineFlags(bc.BGFX_TEXTURE_RT,
                                    bc.BGFX_TEXTURE_COMPARE_LEQUAL)
    return self:addDepthStencilAttachment(depthBits, hasStencil, flags)
end

function RenderTarget:finalize()
    local attachments = self.attachments
    local cattachments = terralib.new(bgfx.bgfx_attachment_t[#attachments])
    for i,v in ipairs(attachments) do
        cattachments[i-1].handle = v -- ffi cstructs are zero indexed
        cattachments[i-1].mip = 0
        cattachments[i-1].layer = 0
    end
    -- if used as the value of a texture uniform, use first attachment
    self.rawTex = self.attachments[1]
    self.frameBuffer = bgfx.bgfx_create_frame_buffer_from_attachment(#attachments, cattachments, true)
    self.cattachments = cattachments
    self.finalized = true
    return self
end

function RenderTarget:construct_(conargs)
    self.constructionArgs_ = {}
    for i,curarg in ipairs(conargs) do
        local attachment = bgfx.bgfx_create_texture_2d(unpack6(curarg))
        table.insert(self.attachments, attachment)
        table.insert(self.constructionArgs_, curarg)
    end
end

-- create a new rendertarget with the same layout as this one
-- does NOT copy the contents of the rendertarget
function RenderTarget:duplicate(finalize)
    local ret = RenderTarget(self.width, self.height)
    ret.hasColor = self.hasColor
    ret.hasDepth = self.hasDepth
    ret.isBackbuffer = self.isBackbuffer
    ret.viewport = self.viewport
    ret:construct_(self.constructionArgs_)
    if finalize ~= false then
        ret:finalize()
    end
    return ret
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

function RenderTarget:setViewport(x, y, width, height)
    self.viewport = {x, y, width, height}
end

function RenderTarget:clearViewport()
    self.viewport = nil
end

function RenderTarget:bindToView(viewid, setViewRect)
    if self.frameBuffer or self.isBackbuffer then
        self.viewid = viewid
        if self.frameBuffer then
            bgfx.bgfx_set_view_frame_buffer(viewid, self.frameBuffer)
        end
        if setViewRect == nil or setViewRect then -- default to true
            if not self.viewport then
                bgfx.bgfx_set_view_rect(viewid, 0, 0, self.width, self.height)
            else
                local vp = self.viewport
                bgfx.bgfx_set_view_rect(viewid, vp[1], vp[2], vp[3], vp[4])
            end
        end
    else
        log.error("Cannot bind null framebuffer to view!")
    end
end

m.RenderTarget = RenderTarget
return m
