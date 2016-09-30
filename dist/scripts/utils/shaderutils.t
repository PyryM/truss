local m = {}
m.programs = {}

function m.loadFileToBGFX(filename)
	local msg = truss.C.load_file(filename)
	if msg == nil then
		error("Error loading shader [" .. filename .. "]; shader missing or uncompiled.")
	end
	local ret = bgfx.bgfx_copy(msg.data, msg.data_length)
	truss.C.release_message(msg)
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
		truss.C.log(truss.C.LOG_ERROR, "Unimplemented shaders for current renderer [" ..
			rendererName .. "]: " .. rendertype)
	end

	return renderpath
end

function m.loadProgram(vshadername, fshadername)
	local pname = vshadername .. "|" .. fshadername
	if m.programs[pname] == nil then
		log.info("Loading program " .. pname)

		local vspath = m.shaderpath() .. vshadername .. ".bin"
		local fspath = m.shaderpath() .. fshadername .. ".bin"

		local vshader = bgfx.bgfx_create_shader(m.loadFileToBGFX(vspath))
		local fshader = bgfx.bgfx_create_shader(m.loadFileToBGFX(fspath))

		log.debug("vidx: " .. vshader.idx)
		log.debug("fidx: " .. fshader.idx)


		m.programs[pname] = bgfx.bgfx_create_program(vshader, fshader, true)
	end

	return m.programs[pname]
end

return m
