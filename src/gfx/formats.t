-- gfx/formats.t
--
-- encapsulations of bgfx formats

local bgfx = require("./bgfx.t")
local m = {}

local bitformats = {
  ["u8"] = {suffix = "8U", ctype = uint8},
  ["u16"] = {suffix = "16U", ctype = uint16},
  ["u32"] = {suffix = "32U", ctype = uint32},
  ["i8"] = {suffix = "8I", ctype = int8},
  ["i16"] = {suffix = "16I", ctype = int16},
  ["i32"] = {suffix = "32I", ctype = int32},
  ["n8"] = {suffix = "8", ctype = uint8},
  ["n16"] = {suffix = "16", ctype = uint16},
  ["f32"] = {suffix = "32F", ctype = float},
  ["f16"] = {suffix = "16F", ctype = uint16}
}

local all_formats = {}
m.texture_formats = all_formats

local function export_tex_format(channels, n_channels, bitformat, has_color, has_depth, has_stencil)
  local bitinfo = bitformats[bitformat]
  local byte_size = terralib.sizeof(bitinfo.ctype)
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
    channel_type = bitinfo.ctype,
    has_color = has_color,
    has_depth = has_depth,
    has_stencil = has_stencil
  }
  all_formats[export_name] = m[export_name]
  return m[export_name]
end

-- special case this kind of weird texture format
m.TEX_R5G6B5 = {
  name = "R5G6B5",
  bgfx_enum = bgfx.TEXTURE_FORMAT_R5G6B5,
  n_channels = 1,
  channel_size = 2,
  pixel_size = 2,
  channel_type = uint16,
  has_color = true,
  has_depth = false,
  has_stencil = false
}

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
export_depth_format("D0S8", true)  -- well ok this also has *only* stencil

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
list_compressed_format("ATC")
list_compressed_format("ATCE")
list_compressed_format("ATCI")
list_compressed_format("ASTC4X4")
list_compressed_format("ASTC5X5")
list_compressed_format("ASTC6X6")
list_compressed_format("ASTC8X5")
list_compressed_format("ASTC8X6")
list_compressed_format("ASTC10X5")

function m.find_format_from_enum(bgfx_enum_val)
  for _, format in pairs(all_formats) do
    if format.bgfx_enum == bgfx_enum_val then
      return format
    end
  end
  return all_formats.unknown_format
end

local format_names = {}
for k, v in pairs(bgfx) do
  local fname = k:match("TEXTURE_FORMAT_(.*)")
  if fname then
    format_names[v] = fname
  end
end

function m.find_name_from_enum(bgfx_enum_val)
  return format_names[bgfx_enum_val]
end

return m