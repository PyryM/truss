-- testo terra file

print("Initializing")

globals = {}
bgfx = terralib.includec("bgfx.c99.h")

function initBGFX()
	local width, height = 800, 600

	local debug = 0x08 --bgfx_constants.BGFX_DEBUG_TEXT
	local reset = 0x80 --bgfx_constants.BGFX_RESET_VSYNC

	bgfx.bgfx_init(7, 0, 0, nil, nil)
	bgfx.bgfx_reset(width, height, reset)

	-- Enable debug text.
	bgfx.bgfx_set_debug(debug)

	bgfx.bgfx_set_view_clear(0, 
	0x0001 + 0x0002, -- clear color + clear depth
	0x303030ff,
	1.0,
	0)

	print("Initted bgfx I hope?")
end

function updateBGFX()
	local width, height = 800, 600

	-- Set view 0 default viewport.
	bgfx.bgfx_set_view_rect(0, 0, 0, width, height);

	-- This dummy draw call is here to make sure that view 0 is cleared
	-- if no other draw calls are submitted to view 0.
	bgfx.bgfx_submit(0, 0);

	-- Use debug font to print information about this example.
	bgfx.bgfx_dbg_text_clear(0, false);

	bgfx.bgfx_dbg_text_printf(0, 1, 0x4f, "fake.t (frame " .. globals.frame .. ")");
	bgfx.bgfx_dbg_text_printf(0, 2, 0x6f, "Description: Interfacing bgfx with terra");

	-- Advance to next frame. Rendering thread will be kicked to
	-- process submitted rendering primitives.
	bgfx.bgfx_frame();
end

function init()
	print("Init called")
	globals.printUpdate = true
	globals.frame = 0
	initBGFX()
end

function update()
	if globals.printUpdate then
		print("Updating from terra/lua")
		print("Supressing further update messages")
		globals.printUpdate = false
	end
	globals.frame = globals.frame + 1
	updateBGFX()
end