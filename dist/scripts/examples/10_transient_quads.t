-- 10_transient_quads.t
--
-- draws a bunch of transient quads
-- illustrates optimization with terra

local AppScaffold = require("utils/appscaffold.t").AppScaffold
local Camera = require("gfx/camera.t").Camera
local geometry = require("gfx/geometry.t")
local shaderutils = require('utils/shaderutils.t')
local math = require("math")
local gfx = require('gfx')

local QuadApp = AppScaffold:extend("QuadApp")
function QuadApp:initPipeline()
    self.pgm = shaderutils.loadProgram("vs_fullscreen", "fs_fullscreen_debug")
    local RenderTarget = require("gfx/rendertarget.t").RenderTarget
    self.backbuffer = RenderTarget(self.width, self.height):makeBackbuffer()
    self.backbuffer:setViewClear(0, {color = 0x303030ff})
    self.backbuffer:bindToView(0)
end

function QuadApp:initScene()
    self.geo = geometry.TransientGeometry()
    self.mat = math.Matrix4():identity()
    self.camera = Camera():makeOrthographic(0, 1, 0, 1, -1, 1)
    self.scene = gfx.Object3D()
end

function QuadApp:naiveDraw(x0, y0, x1, y1)
    -- draw a quad the naive way in Lua
    -- calling a bunch of bgfx function from Lua can be slow, even in luaJIT
    -- this calls *6* bgfx functions per quad
    bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
    bgfx.bgfx_set_transform(self.mat.data, 1)
    self.geo:quad(x0, y0, x1, y1, 0.0):bind()
    bgfx.bgfx_submit(0, self.pgm, 0, false)
end

-- geometry.makeFastTransientQuadFunc emits a *Terra* function specialized
-- for the given vertex format (default: position+texcoord0) which does all
-- the transient buffer allocation, filling, and binding
local fastQuad = geometry.makeFastTransientQuadFunc()

terra fastQuadDraw(x0: float, y0: float, x1: float, y1: float, mat: &float,
                   pgm: bgfx.bgfx_program_handle_t)
    -- draw a quad the fast way, by collecting all the bgfx calls into Terra
    -- this is approximately 6x faster than naiveDraw
    bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
    bgfx.bgfx_set_transform(mat, 1)
    fastQuad(x0, y0, x1, y1, 0.0) -- fastQuad is a Terra func: can be inlined
    bgfx.bgfx_submit(0, pgm, 0, false)
end

-- fastQuadDraw:disas()
-- ^ uncomment to see that Terra has inlined fastQuad into fastQuadDraw

function QuadApp:fastDraw(x0, y0, x1, y1)
    fastQuadDraw(x0, y0, x1, y1, self.mat.data, self.pgm)
end

function QuadApp:render()
    self.camera:setViewMatrices(0)

    local nquads = 5000
    local r = math.random

    for i = 1, nquads do
        local x0, y0 = r(), r()
        local x1, y1 = x0+r()*0.05, y0+r()*0.05
        self:draw(x0, y0, x1, y1)
    end
end

function init()
    app = QuadApp({title = "10_transient_quads",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    --app.draw = app.naiveDraw
    app.draw = app.fastDraw
end

function update()
    app:update()
end
