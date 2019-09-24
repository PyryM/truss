-- gfx/shaders.t
--
-- shader management functions

local bgfx = require("./bgfx.t")
local m = {}

m._programs = {}
m._shaders = {}

local subpaths = {
  DIRECT3D9 = "dx9",
  DIRECT3D11 = "dx11",
  DIRECT3D12 = "dx11", -- not a typo, same shaders
  GNM = "pssl",
  METAL = "metal",
  OPENGLES = "essl",
  OPENGL = "glsl",
  VULKAN = "spirv"
}

function m.get_shader_path()
  local gfx = require("gfx")

  local rendertype = gfx.short_backend_name
  local subpath = subpaths[rendertype]
  if not subpath then truss.error("No subpath for " .. rendertype) end

  return "shaders/" .. subpath .. "/"
end

function m.load_shader(shadername)
  if not m._shaders[shadername] then
    local gfx = require("gfx")

    local shader_path = m.get_shader_path() .. shadername .. ".bin"
    local shader_data = gfx.load_file_to_bgfx(shader_path)
    if not shader_data then
      truss.error("Missing shader [" .. shader_path .. "]")
    end

    m._shaders[shadername] = bgfx.create_shader(shader_data)
  end
  return m._shaders[shadername]
end

function m.load_program(vshadername, fshadername)
  local pname = vshadername .. "|" .. fshadername
  if not m._programs[pname] then
    local vshader = m.load_shader(vshadername)
    local fshader = m.load_shader(fshadername)
    m._programs[pname] = bgfx.create_program(vshader, fshader, true)
    log.debug("Loaded program " .. pname)
  end
  return m._programs[pname]
end

function m.load_compute_program(cshadername)
  local pname = cshadername
  if not m._programs[pname] then
    local cshader = m.load_shader(cshadername)
    m._programs[pname] = bgfx.create_compute_program(cshader, true)
    log.debug("Loaded compute program " .. pname)
  end
  return m._programs[pname]
end

local _error_program = nil
function m.error_program()
  if not _error_program then
    _error_program = m.load_program("vs_error", "fs_error")
  end
  return _error_program
end

return m
