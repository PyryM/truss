local bgfx = require("./bgfx.t") -- make sure bgfx is loaded

local m = {}

local C = terralib.includec("bgfx/bgfx_imageutil.h")
m.C = C

function m.release_image(imgdata)
  C.igBGFXUtilReleaseImage(imgdata)
end

function m.load_image_from_file(fn)
  local data = truss.C.load_file(fn)
  if data == nil then return nil end
  local imdata = terralib.new(C.bgfx_util_imagedata)
  imdata.data = nil
  imdata.datasize = 0
  local ret = nil
  if C.igBGFXUtilDecodeImage(data.data, data.data_length, imdata) then
    ret = ffi.gc(imdata, C.igBGFXUtilReleaseImage)
  end
  truss.C.release_message(data)
  return ret
end

return m