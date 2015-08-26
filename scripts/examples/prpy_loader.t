-- prpy_loader.t
--
-- example of using renderers/simple_renderer.t
-- to render a dart json scenegraph

meshmanager = require("dart/prmeshmanager.t")
matrixlib = require("math/matrix.t")
quatlib = require("math/quat.t")
local OrbitCam = require("gui/orbitcam.t")
gridgen = require("gui/grid.t")

function init()
	app = appscaffold.AppScaffold({
			width = 1280,
			height = 720,
			quality = 1.0,
			title = "prpy loader example"
		})

	-- camera
	camquat = quatlib.Quaternion():fromEuler({x= -math.pi / 2.0,y=0,z=0}, 'ZYX')
	local scale = {x=1, y=1, z=1}
	campos = {x = 0, y = 0, z = 0}

	cammat = matrixlib.Matrix4():compose(camquat, scale, campos)
	app.renderer:setRootTransform(cammat)

	orbitcam = OrbitCam()

	app:setEventHandler(onEvent)

	-- grid
	app.renderer:add(gridgen.createLineGrid())
end

function onEvent(evt)
	orbitcam:updateFromSDL(evt)
end

function innerUpdate()
	orbitcam:update(1.0 / 60.0)
	app.renderer:setCameraTransform(orbitcam.mat)
end

function update()
	app:update(innerUpdate)
end