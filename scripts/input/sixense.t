-- sixense.t
--
-- a wrapper for the sixense (razer hydra) sdk

-- ffi bitops to get button states
local bit = require("bit")

-- link the dynamic library (should only happen once ideally)
terralib.linklibrary("sixense")
local sixense_ = terralib.includec("include/sixense.h")

local m = {}
m.data = terralib.new(sixense_.sixenseAllControllerData)
m.sixense_ = sixense_
m.controllers = {}

function m.init()
	local result = sixense_.sixenseInit()
	if result ~= sixense_.SIXENSE_SUCCESS then
		log.error("Unable to init sixense sdk!")
		return false
	else
		log.info("Sixense SDK connected")
	end
	-- update with SIXENSE_MAX_CONTROLLERS just to populate the
	-- m.controllers structure for all the possible controllers
	-- (unused controllers will just be filled with zeroes)
	m.updateControllers_(sixense_.SIXENSE_MAX_CONTROLLERS)
	return true
end

function m.update()
	sixense_.sixenseGetAllNewestData(m.data)
	m.updateControllers_(m.numControllers())
end

local function interpretController(src, dest)
	-- motion sensing position
	dest.pos = {src.pos[0], src.pos[1], src.pos[2]}
	dest.quat = {src.rot_quat[0], src.rot_quat[1],
				 src.rot_quat[2], src.rot_quat[3]}

	-- joystick
	dest.joy = {src.joystick_x, src.joystick_y}
	dest.trigger = src.trigger

	-- buttons
	local bstate = src.buttons
	local band = bit.band
	dest.button1 	  = band(bstate, sixense_.SIXENSE_BUTTON_1)
	dest.button2 	  = band(bstate, sixense_.SIXENSE_BUTTON_2)
	dest.button3 	  = band(bstate, sixense_.SIXENSE_BUTTON_3)
	dest.button4 	  = band(bstate, sixense_.SIXENSE_BUTTON_4)
	dest.buttonStart  = band(bstate, sixense_.SIXENSE_BUTTON_START)
	dest.buttonJoy    = band(bstate, sixense_.SIXENSE_BUTTON_JOYSTICK)
	dest.buttonBumper = band(bstate, sixense_.SIXENSE_BUTTON_BUMPER)

	-- info
	dest.docked  = src.is_docked > 0
	dest.hand    = src.which_hand
	dest.enabled = src.enabled
end

function m.updateControllers_(nControllers)
	for i = 1, nControllers do
		m.controllers[i] = m.controllers[i] or {}
		interpretController(m.data[i-1], m.controllers[i])
	end
end

function m.numControllers()
	return sixense_.sixenseGetNumActiveControllers()
end

function m.exit()
	sixense_.sixenseExit()
end

return m