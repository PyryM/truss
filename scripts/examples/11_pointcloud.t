-- 11_pointcloud.t
--
-- testing armatures blah

-- start at very beginning to get most log messages
local webconsole = require("devtools/webconsole.t")
--webconsole.start()

local AppScaffold = require("utils/appscaffold.t").AppScaffold
local pbr = require("shaders/pbr.t")
local Object3D = require('gfx/object3d.t').Object3D
local StaticGeometry = require('gfx/geometry.t').StaticGeometry
local vdefs = require('gfx/vertexdefs.t')
local line = require('geometry/line.t')
local grid = require('geometry/grid.t')
local pcloud = require('geometry/pointcloud.t')
local tex = require('gfx/texture.t')
local stringutils = require('utils/stringutils.t')

function createGeometry()
    thegrid = grid.Grid({thickness = 0.01})
    thegrid.quaternion:fromEuler({math.pi/2, 0, 0})
    thegrid:updateMatrix()
    app.scene:add(thegrid)

    pwidth = 128*2
    pheight = 106*2
    ptex = tex.MemTexture(pwidth, pheight)
    thecloud = pcloud.PointCloudObject(pwidth, pheight)
    thecloud:setPlaneSize(1,1)
    thecloud:setPointSize(0.004)
    thecloud.position:set(0.0, 1.0, 0.0)
    thecloud.quaternion:fromEuler({x=-math.pi / 2,y=0,z=0})
    thecloud:updateMatrix()

    -- 128*106
    local bc = core.bgfx_const
    local texflags = bc.BGFX_TEXTURE_MIN_POINT + bc.BGFX_TEXTURE_MAG_POINT
    itex = require('utils/textureutils.t').loadTexture('data/test_half.png', texflags)

    thecloud.mat.texColorDepth = itex --ptex.tex
    --updateTex()
    app.scene:add(thecloud)
end

local function w(x,y,t)
    return 63 * (2.0 + math.sin(x*0.1 + t) + math.cos(y*0.1 + t))
end

function updateTex()
    local d = ptex.data
    local dpos = 0
    for y = 1,pheight do
        for x = 1,pwidth do
            d[dpos+0] = math.random()*255
            d[dpos+1] = math.random()*255
            d[dpos+2] = math.random()*255
            d[dpos+3] = w(x, y, app.time)
            dpos = dpos + 4
        end
    end
    ptex:update()
end

function preRender(appSelf)
    rotator.quaternion:fromEuler({x=0,y=app.time*0.25,z=0})
    rotator:updateMatrix()
end

function testb64()
    local src_str = "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2YgdGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGludWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRoZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4="
    local src = terralib.cast(&uint8, src_str)
    srclen = src_str:len()
    destlen = 1000
    local dest = terralib.new(uint8[destlen+1])
    dest[destlen] = 0 -- null terminate
    local retlen = stringutils.b64decodeRaw(src, srclen, dest, destlen)
    log.info(ffi.string(dest, retlen))
    for i = 0,16 do
        log.info(dest[i])
    end
end

function init()
    testb64()
    app = AppScaffold({title = "adathing",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    app.preRender = preRender

    rotator = Object3D()
    app.scene:add(rotator)
    rotator:add(app.camera)

    app.camera.position:set(0.0, 0.2, 0.75)
    app.camera:updateMatrix()

    app.pipeline:addShader("line", line.LineShader("vs_line", "fs_line_depth"))
    app.pipeline:addShader("pointcloud", pcloud.PointCloudShader(true))

    createGeometry()
end

function update()
    webconsole.update()
    app:update()
    --updateTex()
end
