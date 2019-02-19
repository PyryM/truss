local m = {}
local bgfx = require("gfx/bgfx.t")

if not truss.addons.screencap then
  truss.error("Screencap addon not present.")
  return nil
end

m.started = false
m.rawfunctions = truss.addons.screencap.functions
m.rawpointer = truss.addons.screencap.pointer

function m.start_capture()
  local gfx = require("gfx")
  if not gfx.single_threaded then
    truss.error("Screencap requires single-threaded bgfx.")
    return
  end
  m.started = m.rawfunctions.truss_scap_init(m.rawpointer)
end

function m._update_backing_tex()
  if m.texw and m.texw == m.rawinfo.width and
     m.texh and m.texh == m.rawinfo.height then
       return
  end
  local tw, th = m.rawinfo.width, m.rawinfo.height
  if tw <= 0 or th <= 0 then return end

  log.info("screencap: creating backing texture of size " ..
           tw .. " x " .. th)

  local math = require("math")
  local fmt = bgfx.TEXTURE_FORMAT_BGRA8
  local flags = math.combine_flags(
    --bgfx.TEXTURE_RT,
    bgfx.TEXTURE_BLIT_DST,
    --bgfx.TEXTURE_READ_BACK,
    bgfx.SAMPLER_MIN_POINT,
    bgfx.SAMPLER_MAG_POINT,
    bgfx.SAMPLER_MIP_POINT,
    bgfx.SAMPLER_U_CLAMP,
    bgfx.SAMPLER_V_CLAMP )
  m.tex = bgfx.create_texture_2d(tw, th, false, 1, fmt, flags, nil)
  m.texw = m.rawinfo.width
  m.texh = m.rawinfo.height
  m.tex_info = {width = m.texw, height = m.texh, format = fmt}
end

function m._update_tex()
  --log.info("updating tex?")
  local texptr = bgfx.get_internal_texture_ptr(m.tex)
  if texptr == nil then return false end
  local success = m.rawfunctions.truss_scap_copy_frame_tex_d3d11(m.rawpointer,
                                                                 texptr)
  --log.info("success? " .. tostring(success))
  return success
end

function m.capture_screen()
  if m.has_frame then
    m.rawfunctions.truss_scap_release_frame(m.rawpointer)
  end

  local has_frame = m.rawfunctions.truss_scap_acquire_frame(m.rawpointer)
  if not has_frame then return false end
  m.has_frame = has_frame

  if m.tex then
    if m._update_tex() then
      return m.get_tex()
    else
      return nil
    end
  else
    m.rawinfo = m.rawfunctions.truss_scap_get_frame_info(m.rawpointer)
    m._update_backing_tex()
    return nil
  end
end

function m._create_read_back_tex()
  local math = require("math")
  local flags = math.combine_flags(
      bgfx.TEXTURE_BLIT_DST,
      bgfx.TEXTURE_READ_BACK,
      bgfx.TEXTURE_MIN_POINT,
      bgfx.TEXTURE_MAG_POINT,
      bgfx.TEXTURE_MIP_POINT,
      bgfx.TEXTURE_U_CLAMP,
      bgfx.TEXTURE_V_CLAMP )

  m._read_back_tex = bgfx.create_texture_2d(m.texw, m.texh, false, 1,
                                  bgfx.TEXTURE_FORMAT_BGRA8, flags, nil)
  m._readbackbuffer = truss.C.create_message(m.texw * m.texh * 4)
end

function m.get_data(onsuccess)
  local viewid = 0
  local dMip, dX, dY, dZ = 0, 0, 0, 0
  local sMip, sX, sY, sZ = 0, 0, 0, 0
  local w, h, d = m.texw, m.texh, 0

  if m._read_back_tex == nil then
    m._create_read_back_tex()
  end

  bgfx.blit(viewid, m._read_back_tex, dMip, dX, dY, dZ,
                    m.tex,            sMip, sX, sY, sZ, w, h, d)
  bgfx.read_texture(m._read_back_tex, m._readbackbuffer.data, 0)
  require("gfx").schedule(function()
    onsuccess(m.texw, m.texh, m._readbackbuffer)
  end)
end

function m.get_tex_handle()
  return m.tex
end

function m.get_tex()
  if not m.tex then return nil end
  if not m.wrapped_tex then m.wrapped_tex = {} end
  m.wrapped_tex._handle = m.tex
  m.wrapped_tex._info = m.tex_info
  return m.wrapped_tex
end

return m
