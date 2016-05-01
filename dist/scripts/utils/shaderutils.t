local m = {}
m.programs = {}

terra m.loadFileToBGFX(filename: &int8)
	var msg: &truss.truss_message = truss.truss_load_file(filename)
	var ret: &bgfx.bgfx_memory = bgfx.bgfx_copy(msg.data, msg.data_length)
	truss.truss_release_message(msg)
	return ret
end

function m.shaderpath()
	local rendertype = bgfx.bgfx_get_renderer_type()
	local rendererName = ffi.string(bgfx.bgfx_get_renderer_name(rendertype))
	local renderpath = "shaders/"

	if rendertype == bgfx.BGFX_RENDERER_TYPE_OPENGL then
		renderpath = renderpath .. "glsl/"
	elseif rendertype == bgfx.BGFX_RENDERER_TYPE_DIRECT3D11 then
		renderpath = renderpath .. "dx11/"
	else
		truss.truss_log(0, "Unimplemented shaders for current renderer [" ..
			rendererName .. "]: " .. rendertype)
	end

	return renderpath
end

function m.loadProgram(vshadername, fshadername)
	local pname = vshadername .. "|" .. fshadername
	if m.programs[pname] == nil then
		truss.truss_log(0, "Loading program " .. pname)

		local vspath = m.shaderpath() .. vshadername .. ".bin"
		local fspath = m.shaderpath() .. fshadername .. ".bin"

		local vshader = bgfx.bgfx_create_shader(m.loadFileToBGFX(vspath))
		local fshader = bgfx.bgfx_create_shader(m.loadFileToBGFX(fspath))

		truss.truss_log(0, "vidx: " .. vshader.idx)
		truss.truss_log(0, "fidx: " .. fshader.idx)


		m.programs[pname] = bgfx.bgfx_create_program(vshader, fshader, true)
	end

	return m.programs[pname]
end

return m
