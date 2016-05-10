-- gfx/texture.t
--
-- various texture utilities

local class = require('class')
local m = {}

-- for when you need to create a texture in memory
local MemTexture = class("MemTexture")
function MemTexture:init(w,h)
    self.width = w or 64
    self.height = h or 64
    self.data = terralib.new(uint8[w*h*4])
    self.datasize = w*h*4

    local bc = bgfx_const
    --local flags = 0
    local flags = bc.BGFX_TEXTURE_MIN_POINT +
                  bc.BGFX_TEXTURE_MAG_POINT +
                  bc.BGFX_TEXTURE_MIP_POINT

    -- Note that we pass in nil as the data to allow us to update this texture
    -- later
    self.tex = bgfx.bgfx_create_texture_2d(w, h, 1,
        bgfx.BGFX_TEXTURE_FORMAT_BGRA8, flags, nil)
end

function MemTexture:update()
    bgfx.bgfx_update_texture_2d(self.tex, 0,
                                0, 0, self.width, self.height,
                                bgfx.bgfx_make_ref(self.data, self.datasize),
                                self.width*4)
end

m.MemTexture = MemTexture

return m
