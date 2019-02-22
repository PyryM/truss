local bgfx = require("./bgfx.t")
local math = require("math")
local m = {}

local function parse_supported_features(supported)
  local ret = {}
  for k, mask in pairs(bgfx.raw_constants) do
    if k:sub(1, 10) == "BGFX_CAPS_" and k:sub(1, 17) ~= "BGFX_CAPS_FORMAT_" then
      local capname = k:sub(11, -1):lower()
      ret[capname] = math.ulland(supported, mask) > 0
    end
  end
  return ret
end

local function parse_gpus(caps)
  local ret = {}
  for i = 1, caps.numGPUs do
    ret[i] = {
      vendor_id = caps.gpu[i-1].vendorId,
      device_id = caps.gpu[i-1].deviceId
    }
  end
  return ret
end

local function parse_limits(limits)
  local ret = {}
  local limit_names = {
    "DrawCalls","Blits","TextureSize","TextureLayers","Views","FrameBuffers",
    "FBAttachments","Programs","Shaders","Textures","TextureSamplers",
    "ComputeBindings","VertexDecls","VertexStreams","IndexBuffers",
    "VertexBuffers","DynamicIndexBuffers","DynamicVertexBuffers","Uniforms",
    "OcclusionQueries","Encoders"
  }
  for _, limit_name in ipairs(limit_names) do
    ret[limit_name] = limits["max" .. limit_name]
  end
  return ret
end

local function parse_formats(formats)
  local ret = {}
  for idx = 1, bgfx.TEXTURE_FORMAT_COUNT do
    local flags = formats[idx-1]
    ret[idx] = flags
  end
  return ret
end

function m.get_caps()
  if m._caps then return m._caps end
  if not require("./common.t")._bgfx_initted then
    truss.error("Cannot query capabiities before init.")
  end
  m._caps = {}
  local caps = bgfx.get_caps()
  
  m._caps.vendor_id = caps.vendorId
  m._caps.device_id = caps.deviceId
  m._caps.features = parse_supported_features(caps.supported)
  m._caps.features.homogeneous_depth = caps.homogeneousDepth
  m._caps.features.origin_bottom_left = caps.originBottomLeft
  m._caps.gpus = parse_gpus(caps)
  m._caps.limits = parse_limits(caps.limits)
  m._caps.texture_formats = parse_formats(caps.formats)

  return m._caps
end

return m