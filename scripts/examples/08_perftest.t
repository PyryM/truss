-- 08_perftest.t
--
-- testing raw bgfx drawcall performance

bgfx = core.bgfx
bgfx_const = core.bgfx_const
terralib = core.terralib
trss = core.trss
sdl = addons.sdl

local AppScaffold = require("utils/appscaffold.t").AppScaffold
local debugcube = require("geometry/debugcube.t")
local shaderutils = require('utils/shaderutils.t')
local math = require("math")
local Vector = math.Vector
local Matrix4 = math.Matrix4
local Quaternion = math.Quaternion
local Camera = require("gfx/camera.t").Camera
local Object3D = require('gfx/object3d.t').Object3D

local PerfApp = AppScaffold:extend("PerfApp")
function PerfApp:initPipeline()
    self.pgm = shaderutils.loadProgram("vs_cubes", "fs_cubes")
end

function PerfApp:initScene()
    self.camera = Camera():makeProjection(70, self.width/self.height, 
                                            0.1, 100.0)
    self.camera.position:set(0, 0, 60)
    self.camera:updateMatrix()
    self.geo = debugcube.createGeo()
    self.matrix = Matrix4():identity()
    self.pos = Vector(0,0,0)
    self.scale = Vector(1,1,1)
    self.quat = Quaternion():identity()
end

function PerfApp:render()
    local nside = self.sidesize
    local vbuff = self.geo.vbh
    local ibuff = self.geo.ibh
    local pgm = self.pgm

    self.camera:setViewMatrices(0)

    self.quat:fromEuler({x = self.time, y = self.time, z = 0.0})
    self.matrix:composeRigid(self.pos, self.quat)
    local tmat = self.matrix.data

    for row = 1,nside do
        for col = 1,nside do
            tmat[12] = row - (nside / 2)
            tmat[13] = col - (nside / 2)
            bgfx.bgfx_set_transform(tmat, 1)
            bgfx.bgfx_set_vertex_buffer(vbuff, 0, bgfx.UINT32_MAX)
            bgfx.bgfx_set_index_buffer(ibuff, 0, bgfx.UINT32_MAX)
            bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
            bgfx.bgfx_submit(0, pgm, 0, false)
        end
    end
end

function init()
    app = PerfApp({title = "08_perftest",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    app.sidesize = 100
end

function update()
    app:update()
end