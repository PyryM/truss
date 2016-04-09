-- loadmesh.t
--
-- an example of loading and displaying a mesh

scaffold = require('utils/appscaffold.t')
orbitcam = require('gui/orbitcam.t')
grid = require('gui/grid.t')
soloud = require('sound/soloud.t')
bgfx = core.bgfx
bgfx_const = core.bgfx_const

-- define some globals
camera = nil

function init()
    app = scaffold.AppScaffold({
            width = 1280,
            height = 720
        })

    camera = orbitcam()
    app:setEventHandler(onEvent)

    local thegrid = grid.createLineGrid()
    thegrid.quaternion:fromEuler({x = math.pi / 2.0, y = 0.0, z = 0.0}, 'XYZ')
    app.renderer:add(thegrid)

    soloud.init()
    --bgmusic = soloud.loadWav("sounds/tetsno.ogg")
    bgmusic = soloud.loadWav("sounds/thingy.wav")
    bgmusic:setLooping(true)
    bgmusic:play()

    hitsound = soloud.loadWav("sounds/spacebutton_2.wav")

    speech = soloud.createSpeech()
    speech:say("what words is it good at saying", 5.0)
end

function onEvent(evt)
    camera:updateFromSDL(evt)
end

function ourUpdate()
    camera:update(1.0 / 60.0)
    app.renderer:setCameraTransform(camera.mat)
    local volume = math.random() * 4 + 1.0
    if math.random() < 0.10 and hitsound then hitsound:play(volume) end
end

function update()
    app:update(ourUpdate)
end