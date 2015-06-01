local m = {}
m.programs = {}

terra m.loadFileToBGFX(filename: &int8)
	var msg: &trss.trss_message = trss.trss_load_file(filename, 0)
	var ret: &bgfx.bgfx_memory = bgfx.bgfx_copy(msg.data, msg.data_length)
	trss.trss_release_message(msg)
	return ret
end

function m.shaderpath()
	-- TODO: have this actually switch based on renderer
	if not m.pathWarning then
		trss.trss_log(0, "Warning: shaderpath hardcoded to dx11 at the moment!")
		m.pathWarning = true
	end
	return "shaders/dx11/"
end

function m.loadProgram(vshadername, fshadername)
	local pname = vshadername .. "|" .. fshadername
	if m.programs[pname] == nil then
		trss.trss_log(0, "Loading program " .. pname)

		local vspath = m.shaderpath() .. vshadername .. ".bin"
		local fspath = m.shaderpath() .. fshadername .. ".bin"

		local vshader = bgfx.bgfx_create_shader(m.loadFileToBGFX(vspath))
		local fshader = bgfx.bgfx_create_shader(m.loadFileToBGFX(fspath))

		trss.trss_log(0, "vidx: " .. vshader.idx)
		trss.trss_log(0, "fidx: " .. fshader.idx)


		m.programs[pname] = bgfx.bgfx_create_program(vshader, fshader, true)
	end

	return m.programs[pname]
end

return m