local bgfx = require("./bgfx.t") -- make sure bgfx is loaded
local build = require("build/build.t")
local ffi = require("ffi")

local m = {}

local C = build.includec("bgfx/bgfx_imageutil.h")
m.C = C

function m.release_image(imgdata)
  C.igBGFXUtilReleaseImage(imgdata)
end

function m.load_image_from_file(fn)
  assert(build.is_native(), "cannot actually call image load functions in cross-compilation context!")
  local data = truss.read_file_buffer(fn)
  if data == nil then return nil end
  local imdata = terralib.new(C.bgfx_util_imagedata)
  imdata.data = nil
  imdata.datasize = 0
  local ret = nil
  if C.igBGFXUtilDecodeImage(data.data, data.size, imdata) then
    ret = ffi.gc(imdata, C.igBGFXUtilReleaseImage)
  end
  return ret
end

return m