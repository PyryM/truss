-- 09_fullscreen_quad.t
--
-- this just draws a full screen quad

local AppScaffold = require("utils/appscaffold.t").AppScaffold
local Camera = require("gfx/camera.t").Camera
local geometry = require("gfx/geometry.t")
local shaderutils = require('utils/shaderutils.t')
local math = require("math")
local bgfx = core.bgfx
local bgfx_const = core.bgfx_const
local gfx = require("gfx")

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

function QuadApp:render()
    self.camera:setViewMatrices(0)
    bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
    bgfx.bgfx_set_transform(self.mat.data, 1)
    self.geo:fullScreenTri(1.0, 1.0):bind()
    bgfx.bgfx_submit(0, self.pgm, 0, false)
end

function init()
    app = QuadApp({title = "09_fullscreen_quad",
                       width = 1280,
                       height = 720,
                       usenvg = false})
end

function update()
    app:update()
end
