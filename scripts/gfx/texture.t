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
    self.newdata = terralib.new(uint8[w*h*4])
    self.datasize = w*h*4
    for i = 0,self.datasize-1 do
        self.data[i] = math.random()*255
    end
    local bmem = bgfx.bgfx_make_ref(self.data, self.datasize)
    local flags = 0
    self.tex = bgfx.bgfx_create_texture_2d(w, h, 1,
        bgfx.BGFX_TEXTURE_FORMAT_BGRA8, flags, bmem)
end

function MemTexture:update()
    bgfx.bgfx_update_texture_2d(self.tex,
                                0, 0, 0, self.width, self.height,
                                bgfx.bgfx_make_ref(self.newdata, self.datasize),
                                65535)
end

m.MemTexture = MemTexture

return m
