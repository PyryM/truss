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

function createGeometry()
    thegrid = grid.Grid({thickness = 0.01})
    thegrid.quaternion:fromEuler({math.pi/2, 0, 0})
    thegrid:updateMatrix()
    app.scene:add(thegrid)

    pwidth = 256
    pheight = 256
    ptex = tex.MemTexture(pwidth, pheight)
    thecloud = pcloud.PointCloudObject(pwidth, pheight)

    --itex = require('utils/textureutils.t').loadTexture('test.png')

    thecloud.mat.texColorDepth = ptex.tex
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

function init()
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
    app.pipeline:addShader("pointcloud", pcloud.PointCloudShader())

    createGeometry()
end

function update()
    webconsole.update()
    app:update()
    updateTex()
end
