-- linemod_synth.t
--
-- example of using renderers/simple_renderer.t
-- to render synthetic data for linemod
--
-- Note: press F5 to start saving images

-- Options:
modelname = args[3]
modeltex = args[4]
destdir = args[5] or "data"
thetasteps = 40
phisteps = 20
objlocation = {0,0,-0.4} -- object location in opengl camera frame
					   -- (+x right, +y up, -z into the screen)


-- Main script:
bgfx = libs.bgfx
bgfx_const = libs.bgfx_const
terralib = libs.terralib
trss = libs.trss
sdl = libs.sdl
sdlPointer = libs.sdlPointer
nvgAddonPointer = libs.nvgAddonPointer
nvgUtils = libs.nvgUtils
TRUSS_ID = libs.TRUSS_ID
nanovg = libs.nanovg

function init()
	trss.trss_log(TRUSS_ID, "linemod_synth.t init")
	sdl.trss_sdl_create_window(sdlPointer, width, totalheight, 'LINEMOD SYNTH')
	initBGFX()
	initNVG()
	local rendererType = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendererType))
	trss.trss_log(TRUSS_ID, "Renderer type: " .. rendererName)
end

width = 1024
viewheight = 512
totalheight = 550
frame = 0
time = 0.0
mousex, mousey = 0, 0

frametime = 0.0

stlloader = truss_import("loaders/stlloader.t")
objloader = truss_import("loaders/objloader.t")
meshutils = truss_import("mesh/mesh.t")
textureutils = truss_import("utils/textureutils.t")
simple_renderer = truss_import("renderers/simple_renderer.t")
colorcoder = truss_import("utils/colorcoder.t")

screenshotid = 0
screenshotpath = destdir

savingShots = false
shotsLeft = thetasteps * phisteps
curShot = 1

-- create the list of shots
shotlist = {}
for thetaidx = 1,thetasteps do
	local theta = (thetaidx - 1) * math.pi * 2.0 / thetasteps
	for phiidx = 1,phisteps do
		local phi = ((phiidx - 1) * math.pi / phisteps) - math.pi / 2.0
		table.insert(shotlist, {theta = theta, phi = phi})
	end
end

function takeScreenshot()
	local fn = screenshotpath .. "/img_" .. screenshotid .. ".png"
	bgfx.bgfx_save_screen_shot(fn)
	screenshotid = screenshotid + 1
end

function updateEvents()
	local nevents = sdl.trss_sdl_num_events(sdlPointer)
	for i = 1,nevents do
		local evt = sdl.trss_sdl_get_event(sdlPointer, i-1)
		if evt.event_type == sdl.TRUSS_SDL_EVENT_MOUSEMOVE then
			mousex = evt.x
			mousey = evt.y
		elseif evt.event_type == sdl.TRUSS_SDL_EVENT_KEYDOWN or evt.event_type == sdl.TRUSS_SDL_EVENT_KEYUP then
			local sname = "up"
			local keyname = ffi.string(evt.keycode)
			if evt.event_type == sdl.TRUSS_SDL_EVENT_KEYDOWN then
				if keyname == "F5" then
					savingShots = true
				elseif keyname == "F10" then
					takeScreenshot()
				end
				sname = "down" 
			end
			trss.trss_log(0, "Key event: " .. sname .. " " .. keyname)
			trss.trss_log(0, "x: " .. evt.x .. ", y: " .. evt.y .. ", flags: " .. evt.flags)
		elseif evt.event_type == sdl.TRUSS_SDL_EVENT_WINDOW and evt.flags == 14 then
			trss.trss_log(TRUSS_ID, "Received window close, stopping interpreter...")
			trss.trss_stop_interpreter(TRUSS_ID)
		end
	end
end

function log(msg)
	trss.trss_log(0, msg)
end

function initNVG()
	nvg = nanovg.nvgCreate(0, 2) -- antialiasing, viewid
	bgfx.bgfx_set_view_seq(1, true)
	nvgfont = nanovg.nvgCreateFont(nvg, "sans", "font/VeraMono.ttf")
end

function ltostr(l)
	local ret = ""
	for i,v in ipairs(l) do
		ret = ret .. v .. ","
	end
	return ret
end

function renderNVG()
	nanovg.nvgBeginFrame(nvg, width, totalheight, 1.0)

	-- because NVG hijacks the view rect, we have to manually clear just the
	-- part NVG will be 'allowed' to draw into
	nanovg.nvgBeginPath(nvg)
	nanovg.nvgRect(nvg, 0, viewheight, width, totalheight-viewheight)
	nanovg.nvgFillColor(nvg, nanovg.nvgRGBA(0,0,0,255))
	nanovg.nvgFill(nvg)

	nanovg.nvgFontSize(nvg, 14)
	nanovg.nvgFillColor(nvg, nanovg.nvgRGBA(255,255,255,255))

	nanovg.nvgText(nvg, 0, totalheight, "T: " .. ltostr(targetinfo), nil)

	colorcoder.encodeFloats(nvg, targetinfo, 0, viewheight, 4, 4)

	nanovg.nvgEndFrame(nvg)
end

function initBGFX()
	-- Basic init

	local debug = bgfx_const.BGFX_DEBUG_TEXT
	local reset = bgfx_const.BGFX_RESET_VSYNC -- antialiasing will distort depth encoding
	--local reset = bgfx_const.BGFX_RESET_VSYNC + bgfx_const.BGFX_RESET_MSAA_X8
	--local reset = bgfx_const.BGFX_RESET_MSAA_X8

	local cbInterfacePtr = sdl.trss_sdl_get_bgfx_cb(sdlPointer)

	bgfx.bgfx_init(bgfx.BGFX_RENDERER_TYPE_COUNT, 0, 0, cbInterfacePtr, nil)
	bgfx.bgfx_reset(width, totalheight, reset)

	-- Enable debug text.
	bgfx.bgfx_set_debug(debug)

	bgfx.bgfx_set_view_clear(0, 
	bgfx_const.BGFX_CLEAR_COLOR + bgfx_const.BGFX_CLEAR_DEPTH,
	0x303030ff, -- clear color
	1.0, -- clear depth (in clip space?)
	0) -- flags??

	bgfx.bgfx_set_view_clear(1, 
	bgfx_const.BGFX_CLEAR_COLOR + bgfx_const.BGFX_CLEAR_DEPTH,
	0x000000ff,
	1.0,
	0)

	-- draw UI overlays last, don't clear color
	bgfx.bgfx_set_view_clear(2, 
	bgfx_const.BGFX_CLEAR_DEPTH,
	0x000000ff,
	1.0,
	0)

	trss.trss_log(0, "Initted bgfx I hope?")

	-- Init renderers
	leftrenderer = simple_renderer.SimpleRenderer(width/2, viewheight)
	leftrenderer.useColors = false -- we will be using colors as IDs
	rightrenderer = simple_renderer.SimpleRenderer(width/2, viewheight)
	leftrenderer.viewid = 0

	-- Tweak right renderer: depth program,
	--                       no matrix updates (left renderer will do that)
	--                       viewid = 1
	rightrenderer:setProgram("vs_depth", "fs_depth_mono")
	rightrenderer:setTexProgram("vs_depth", "fs_depth_mono")
	rightrenderer.viewid = 1
	--rightrenderer.autoUpdateMatrices = false

	-- Load the model
	objloader.verbose = true
	stlloader.verbose = true

	targetdata = objloader.loadOBJ(modelname, false)
	if modelname ~= nil then
		targettex = textureutils.loadTexture(modeltex)
		targetgeo = meshutils.Geometry():fromData(leftrenderer.vertexInfo, targetdata)
		targetmat = {texture = targettex, color = {1,1,1}}
	else
		targetmat = {color = {1,1,1}}
	end
	thetarget = meshutils.Mesh(targetgeo, targetmat)

	-- tx,ty,tz,rx,ry,rz,rw
	targetinfo = {objlocation[1],objlocation[2],objlocation[3],0,0,0,0}

	trss.trss_log(0, "OBJ: " .. objlocation[1] .. ", " .. objlocation[2] .. ", " .. objlocation[3])
	thetarget.position.x = objlocation[1]
	thetarget.position.y = objlocation[2]
	thetarget.position.z = objlocation[3]

	thetarget.quaternion:fromEuler({x=1.5,y=1.5,z=1.5},'ZYX')
	
	-- simplerenderer just stores references, so we can safely do this
	leftrenderer:add(thetarget)
	rightrenderer:add(thetarget)
end

function randRange(minv, maxv)
	return math.random() * (maxv - minv) + minv
end

function randomizeTarget()
	thetarget.position.x = objlocation[1]
	thetarget.position.y = objlocation[2]
	thetarget.position.z = objlocation[3]

	local rot = {x = shotlist[curShot].phi,
				 y = 0.0, --shotlist[curShot].theta,
				 z = shotlist[curShot].theta}
	thetarget.quaternion:fromEuler(rot, 'XYZ')

	--thetarget.scale.x, thetarget.scale.y, thetarget.scale.z = 0.01,0.01,0.01

	targetinfo = {
		thetarget.position.x,
		thetarget.position.y,
		thetarget.position.z,
		thetarget.quaternion.x,
		thetarget.quaternion.y,
		thetarget.quaternion.z,
		thetarget.quaternion.w
	}

	curShot = curShot + 1
end

frametime = 0.0

function render()
	-- set up splitscreen viewports
	local w2 = width / 2

	bgfx.bgfx_set_view_rect(0,  0, 0, w2, viewheight)
	bgfx.bgfx_set_view_rect(1, w2, 0, w2, viewheight)
	--bgfx.bgfx_set_view_rect(2,  0, viewheight, width, totalheight - viewheight)

	-- do actual rendering
	leftrenderer:render()
	rightrenderer:render()

	-- text
	renderNVG()
end

function update()
	frame = frame + 1
	time = time + 1.0 / 60.0

	local startTime = tic()

	-- Deal with input events
	updateEvents()

	if (savingShots and shotsLeft > 0) or dryRun then
		randomizeTarget()
	end

	render()

	bgfx.bgfx_dbg_text_clear(0, false)

	if savingShots and shotsLeft > 0 then
		takeScreenshot()
		shotsLeft = shotsLeft - 1
	elseif shotsLeft <= 0 then
		bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "Done.")
	else
		bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "Press F5 to generate images")
		bgfx.bgfx_dbg_text_printf(0, 2, 0x4f, "Model: " .. modelname .. ", Tex: " .. modeltex)
		bgfx.bgfx_dbg_text_printf(0, 3, 0x4f, "Destination: " .. destdir)
	end

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame()

	frametime = toc(startTime)
end