-- 08_perftest.t
--
-- testing raw bgfx drawcall performance

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
local CMath = terralib.includec("math.h")


local PerfApp = AppScaffold:extend("PerfApp")
function PerfApp:initPipeline()
    self.pgm = shaderutils.loadProgram("vs_cubes", "fs_cubes")
end

function PerfApp:initScene()
    self.camera = Camera():makeProjection(70, self.width/self.height, 
                                            1.0, 200.0)
    self.camera.position:set(0, 0, 150)
    self.camera:updateMatrix()
    self.geo = debugcube.createGeo()
    self.matrix = Matrix4():identity()
    self.pos = Vector(0,0,0)
    self.scale = Vector(1,1,1)
    self.quat = Quaternion():identity()
end

function PerfApp:bindFFIBGFX()
    local ffi = require("ffi")
        -- typedef struct bgfx_vertex_buffer_handle { uint16_t idx; } bgfx_vertex_buffer_handle_t;
        -- typedef struct bgfx_index_buffer_handle { uint16_t idx; } bgfx_index_buffer_handle_t;    
        -- typedef struct bgfx_program_handle { uint16_t idx; } bgfx_program_handle_t;

    ffi.cdef[[
        typedef struct bbgfx_vertex_buffer_handle { uint16_t idx; } bbgfx_vertex_buffer_handle_t;
        typedef struct bbgfx_index_buffer_handle { uint16_t idx; } bbgfx_index_buffer_handle_t;    
        typedef struct bbgfx_program_handle { uint16_t idx; } bbgfx_program_handle_t;
        uint32_t bgfx_set_transform(const void* _mtx, uint16_t _num);
        void bgfx_set_index_buffer(bbgfx_index_buffer_handle_t _handle, uint32_t _firstIndex, uint32_t _numIndices);
        void bgfx_set_state(uint64_t _state, uint32_t _rgba);
        void bgfx_set_vertex_buffer(bbgfx_vertex_buffer_handle_t _handle, uint32_t _startVertex, uint32_t _numVertices);
        uint32_t bgfx_submit(uint8_t _id, bbgfx_program_handle_t _handle, int32_t _depth, bool _preserveState);
    ]]
    self.ffibgfx = ffi.load("bgfx-shared-libRelease")
    self.usingFFI = true
    self.ffivbh = ffi.new("bbgfx_vertex_buffer_handle_t")
    self.ffivbh.idx = self.geo.vbh.idx
    self.ffiibh = ffi.new("bbgfx_index_buffer_handle_t")
    self.ffiibh.idx = self.geo.ibh.idx
    self.ffipgm = ffi.new("bbgfx_program_handle_t")
    self.ffipgm.idx = self.pgm.idx
end

function PerfApp:render()
    local bgfx = core.bgfx
    local bgfx_const = core.bgfx_const
    local umax = 4294967295
    --bgfx.UINT32_MAX or 

    local nside = self.sidesize
    local vbuff = self.geo.vbh
    local ibuff = self.geo.ibh
    local pgm = self.pgm

    if self.usingFFI then
        bgfx = self.ffibgfx
        vbuff = self.ffivbh
        ibuff = self.ffiibh
        pgm = self.ffipgm
    end

    self.camera:setViewMatrices(0)

    self.quat:fromEuler({x = self.time, y = self.time, z = 0.0})
    self.matrix:composeRigid(self.pos, self.quat)
    local tmat = self.matrix.data

    if self.fakeCalls then
        local sumval = 0.0
        local t = self.time
        for row = 1,nside do
            for col = 1,nside do
                tmat[12] = row*2 - nside
                tmat[13] = col*2 - nside
                sumval = sumval + CMath.sinf(row+t)
                sumval = sumval + CMath.cosf(row+t)
                sumval = sumval + CMath.sinf(col+t)
                sumval = sumval + CMath.cosf(col+t)
                sumval = sumval + CMath.sinf(col+row+t)
            end
        end
        log.info("sumval: " .. sumval)
    else
        for row = 1,nside do
            for col = 1,nside do
                tmat[12] = row*2 - nside
                tmat[13] = col*2 - nside
                bgfx.bgfx_set_state(bgfx_const.BGFX_STATE_DEFAULT, 0)
                bgfx.bgfx_set_transform(tmat, 1)
                bgfx.bgfx_set_vertex_buffer(vbuff, 0, umax)
                bgfx.bgfx_set_index_buffer(ibuff, 0, umax)
                bgfx.bgfx_submit(0, pgm, 0, false)
            end
        end
    end
end

function init()
    app = PerfApp({title = "08_perftest",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    app.sidesize = 100
    --app.fakeCalls = true
    --app:bindFFIBGFX()
end

function update()
    app:update()
end