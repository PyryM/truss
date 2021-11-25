local math = require("math")
local Vector = math.Vector
local imapp = require("app/immediateapp.t")
local gfx = require("gfx")

local function update_tex(tex, t)
  local data = tex.cdata
  local p = 0
  for r = 0, tex.height-1 do
    for c = 0, tex.width-1 do
      data[p] = 128+127*math.sin(r*0.1+t)
      data[p+1] = 128+127*math.cos(r*0.1+t)
      data[p+2] = 128+127*math.sin((r+c)*0.15+t)
      data[p+3] = 255
      p = p + 4
    end
  end
end

local function render(ctx)
  local tex = gfx.Texture2d{
    width = 512,
    height = 512,
    dynamic = true,
    allocate = true,
    format = assert(gfx.TEX_RGBA8)
  }
  tex:commit()

  local mat = gfx.anonymous_material{
    uniforms = {s_srcTex = {0, tex}},
    state = {cull = false, depth_test = false, depth_write = false},
    program = {"vs_fullscreen", "fs_fullscreen_copy"}
  }

  local f = 0
  while true do
    f = f + 1
    ctx:await_frame()
    ctx:await_view{
      proj_matrix = math.Matrix4():orthographic_projection(
        0, 1,
        0, 1, 
        -1.0, 1.0, false
      ),
      view_matrix = math.Matrix4():identity(),
      clear = {color = 0xffffffff, depth = 1.0},
      render_target = gfx.BACKBUFFER
    }
    update_tex(tex, f*0.1)
    tex:update()
    ctx:draw_fullscreen(mat)
  end
  truss.quit()
end

function init()
  app = imapp.ImmediateApp{
    width = 512, height = 512,
    num_views = 32,
    func = render,
  }
end

function update()
  app:update()
end