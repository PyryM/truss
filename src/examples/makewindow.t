local sdl = require("addon/sdl.t")
local gfx = require("gfx")

function init()
  sdl.create_window(1280, 720, 'truss', 0, 0)
  gfx.init_gfx{
    lowlatency = true,
    window = sdl
  }
end

function update()
  -- eh
end