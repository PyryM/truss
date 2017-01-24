-- pointcloud.t
--
-- testing pointcloud viewing

-- start at very beginning to get most log messages
local webconsole = require("devtools/webconsole.t")
webconsole.start()

local AppScaffold = require("utils/appscaffold.t").AppScaffold
local pbr = require("shaders/pbr.t")
local gfx = require("gfx")
local line = require('geometry/line.t')
local grid = require('geometry/grid.t')
local pcloud = require('geometry/pointcloud.t')
local stringutils = require('utils/stringutils.t')
local websocket = require('io/websocket.t')
local jsonimage = require('sandbox/jsonimage.t')
local orbitcam = require("gui/orbitcam.t")

function createGeometry()
    thegrid = grid.Grid({thickness = 0.01})
    thegrid.quaternion:fromEuler({math.pi/2, 0, 0})
    thegrid:updateMatrix()
    app.scene:add(thegrid)

    pwidth = 256 --512/2
    pheight = 212 --424/2
    ptex = gfx.MemTexture(pwidth, pheight)
    thecloud = pcloud.PointCloudObject(pwidth, pheight)
    thecloud:setPlaneSize(0.7*2,0.57*2)
    thecloud:setPointSize(0.004)
    thecloud:setDepthLimits(0.3, 3.0)
    thecloud.quaternion:fromEuler({-0.55,0,0})
    thecloud.position:set(0,1,0)
    thecloud:updateMatrix()

    -- 128*106
    local bc = core.bgfx_const
    local texflags = bc.BGFX_TEXTURE_MIN_POINT + bc.BGFX_TEXTURE_MAG_POINT
    itex = require('utils/textureutils.t').loadTexture('textures/cone.png', texflags)

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

function swizzleTex()
    local d = ptex.data
    local dpos = 0
    for y = 1,pheight do
        for x = 1,pwidth do
            -- r,g,b,a
            local r,g,b,a = d[dpos+0], d[dpos+1], d[dpos+2], d[dpos+3]
            d[dpos+0], d[dpos+1], d[dpos+2], d[dpos+3] = b,g,a,r
            dpos = dpos + 4
        end
    end
end

function decodeMessageToTex(msg)
    local stime = tic()

    if msg == nil then
        log.error("Cannot decode nil!")
        return
    end

    --jsonimage.verbose = true
    local ndecoded = jsonimage.decode(msg, ptex.data, ptex.datasize)
    --log.info("Decoded " .. ndecoded .. " bytes.")

    --swizzleTex()
    ptex:update()

    local deltatime = toc(stime)
    --log.info("Decoding took " .. deltatime*1000.0 .. " ms")
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
    --testb64()
    app = AppScaffold({title = "adathing",
                       width = 1280,
                       height = 720,
                       usenvg = false})
    app.userEventHandler = onSdlEvent

    camerarig = orbitcam.OrbitCameraRig(app.camera)
    camerarig:setZoomLimits(0.2, 10.0)
    camerarig:set(0, 0, 5.0)

    local geostage = app.pipeline.stages.forwardpass
    geostage:addShader("line", line.LineShader("vs_line", "fs_line_depth"))
    geostage:addShader("pointcloud", pcloud.PointCloudShader(true))

    createGeometry()
    --local msg = loadStringFromFile("capture.json")
    --local msg = loadStringFromFile("capture.json")
    --decodeMessageToTex(msg)
    connect()
end

function onSdlEvent(selfapp, evt)
    camerarig:updateFromSDL(evt)
end

theSocket = nil

function onWSMessage(jsonstring)
    decodeMessageToTex(jsonstring)
end

function connect()
    local url = "ws://localhost:8080"
    log.info("Connecting to [" .. url .. "]")
    if theSocket == nil then
        theSocket = websocket.WebSocketConnection()
    end
    theSocket:onMessage(onWSMessage)
    theSocket:connect(url)
    if not theSocket.open then
        log.error("Socket does not appear to be open.")
    end
    log.info("Sending message!")
    local msg = {"subscribe", {"depthdata"}}
    theSocket:sendJSON(msg)
    log.info("Sent message!")
    return theSocket
end

function update()
    webconsole.update()
    camerarig:update(1.0 / 60.0)
    if theSocket then
        theSocket:update()
    end
    app:update()
    --updateTex()
end
