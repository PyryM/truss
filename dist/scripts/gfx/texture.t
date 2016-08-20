-- gfx/texture.t
--
-- various texture utilities

local class = require('class')
local m = {}

-- for when you need to create a texture in memory
local MemTexture = class("MemTexture")
m.MemTexture = MemTexture

local formats = {
    RGBA8 = {uint8, bgfx.BGFX_TEXTURE_FORMAT_BGRA8, 4, 4},
    RG16  = {uint16, bgfx.BGFX_TEXTURE_FORMAT_RG16, 2, 4}
}

function MemTexture:init(w,h,fmt)
    self.width = w or 64
    self.height = h or 64
    self.fmt = fmt or "RGBA8"
    local fmtinfo = formats[self.fmt]
    local datatype, bgfxformat, nchannels, psize =
          fmtinfo[1], fmtinfo[2], fmtinfo[3], fmtinfo[4]
    self.data = terralib.new(datatype[w*h*nchannels])
    self.datasize = w*h*psize
    self.pitch = self.width * psize

    local bc = bgfx_const
    --local flags = 0
    local flags = bc.BGFX_TEXTURE_MIN_POINT +
                  bc.BGFX_TEXTURE_MAG_POINT +
                  bc.BGFX_TEXTURE_MIP_POINT

    -- Note that we pass in nil as the data to allow us to update this texture
    -- later
    self.tex = bgfx.bgfx_create_texture_2d(w, h, 1, bgfxformat, flags, nil)
    -- allow a MemTexture to directly be used as a uniform value
    self.rawTex = self.tex
end

function MemTexture:update()
    bgfx.bgfx_update_texture_2d(self.tex, 0,
                                0, 0, self.width, self.height,
                                bgfx.bgfx_make_ref(self.data, self.datasize),
                                self.pitch)
end

terra m.createTextureFromData(w: int32, h: int32, src: &uint8, srclen: uint32, flags: uint32) : bgfx.bgfx_texture_handle_t
    var bmem: &bgfx.bgfx_memory = nil
    if src ~= nil then
        bmem = bgfx.bgfx_copy(src, srclen)
    else
        truss.truss_log(truss.TRUSS_LOG_ERROR, "Error creating texture: null pointer")
        var ret : bgfx.bgfx_texture_handle_t
        ret.idx = bgfx.BGFX_INVALID_HANDLE
        return ret
    end
    var ret = bgfx.bgfx_create_texture_2d(w, h, 0, bgfx.BGFX_TEXTURE_FORMAT_RGBA8, flags, bmem)
    return ret
end

return m
