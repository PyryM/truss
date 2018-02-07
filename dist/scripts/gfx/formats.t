-- gfx/formats.t
--
-- encapsulations of bgfx formats

local m = {}

local bitformats = {
  [uint8] = {suffix = "8"},
  [uint16] = {suffix = "16"},
  [float] = {suffix = "32F"},
  ["halffloat"] = {bytes = 2, suffix = "16F", proxy_type = uint16}
}

local all_formats = {}

local function export_tex_format(channels, n_channels, bitformat, has_color, has_depth, has_stencil)
  local bitinfo = bitformats[bitformat]
  local byte_size = bitinfo.bytes or terralib.sizeof(bitformat)
  local fname = string.upper(channels) .. bitinfo.suffix
  local bgfx_enum = bgfx["TEXTURE_FORMAT_" .. fname]
  if not bgfx_enum then 
    log.debug("No bgfx format " .. fname)
    return
  end
  local export_name = "TEX_" .. fname
  m[export_name] = {
    name = fname,
    bgfx_enum = bgfx_enum,
    n_channels = n_channels,
    channel_size = byte_size,
    pixel_size = byte_size * n_channels,
    channel_type = bitinfo.proxy_type or bitformat,
    has_color = has_color,
    has_depth = has_depth,
    has_stencil = has_stencil
  }
  all_formats[export_name] = m[export_name]
  return m[export_name]
end

-- color formats
local channel_names = {R = 1, RG = 2, RGBA = 4, BGRA = 4}
for channel_name, n_channels in pairs(channel_names) do
  for bitformat, _ in pairs(bitformats) do
    export_tex_format(channel_name, n_channels, bitformat, true, false, false)
  end
end

-- depth texture formats
-- since these are typically not meant to be read back, we don't need to fill
-- in things like pixel sizes
local function export_depth_format(name, has_stencil)
  local bgfx_enum = bgfx["TEXTURE_FORMAT_" .. name]
  local export_name = "TEX_" .. name
  m[export_name] = {
    name = name,
    bgfx_enum = bgfx_enum,
    has_color = false,
    has_depth = true,
    has_stencil = has_stencil or false
  }
  all_formats[export_name] = m[export_name]
end

export_depth_format("D16",  false)
export_depth_format("D24",  false)
export_depth_format("D24S8", true) -- this is the only one with stencil
export_depth_format("D32",  false)
export_depth_format("D16F", false)
export_depth_format("D24F", false)
export_depth_format("D32F", false)

-- compressed formats aren't exported, and can only appear when loading
-- a texture from a ktx, dds, etc.
local function list_compressed_format(name)
  local bgfx_enum = bgfx["TEXTURE_FORMAT_" .. name]
  all_formats["TEX_" .. name] = {
    name = name,
    bgfx_enum = bgfx_enum,
    has_color = true,
    compressed = true
  }
end

list_compressed_format("BC1")
list_compressed_format("BC2")
list_compressed_format("BC3")
list_compressed_format("BC4")
list_compressed_format("BC5")
list_compressed_format("BC6H")
list_compressed_format("BC7")
list_compressed_format("ETC1")
list_compressed_format("ETC2")
list_compressed_format("ETC2A")
list_compressed_format("ETC2A1")
list_compressed_format("PTC12")
list_compressed_format("PTC14")
list_compressed_format("PTC12A")
list_compressed_format("PTC14A")
list_compressed_format("PTC22")
list_compressed_format("PTC24")

function m.find_format_from_enum(bgfx_enum_val)
  for _, format in pairs(all_formats) do
    if format.bgfx_enum == bgfx_enum_val then
      return format
    end
  end
  return all_formats.unknown_format
end

return m