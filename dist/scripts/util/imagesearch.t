-- util/imagesearch.t
--
-- searches an image for a subimage

local m = {}

local terra check_bin_pos(w: uint32, h: uint32, src: &uint8, chan: uint32,
                          kw: uint32, kh: uint32, kernel: &uint8, bsize: uint32,
                          x: uint32, y: uint32)
  var kpos = 0
  for ky = 0, kh do
    var spos = (y+(ky*bsize))*w*4 + x*4 + chan
    for kx = 0, kw do
      if (src[spos] > 128) ~= (kernel[kpos] > 0) then return false end
      spos = spos + 4*bsize
      kpos = kpos + 1
    end
  end
  return true
end

local struct ReturnPos {
  x: int32;
  y: int32;
}

function m.load_binary_target(filename)
  local gfx = require("gfx")
  local targetdata = gfx.load_texture_data(filename)
  log.info(targetdata.w .. ", " .. targetdata.h .. ", " .. targetdata.n)
  targetdata.kernel = terralib.new(uint8[targetdata.w * targetdata.h])
  for i = 0,(targetdata.w*targetdata.h)-1 do
    targetdata.kernel[i] = targetdata.data[i*4]
  end
  return targetdata
end

-- w, h, src: src image (assumed bgra8)
-- chan: color channel in src to search in
-- kw, kh, kernel: binary subimage to search for
-- bsize: how big a subimage block is
terra m.binary_subimage_search(w: uint32, h: uint32, src: &uint8, chan: uint32,
                             kw: uint32, kh: uint32, kernel: &uint8, bsize: uint32)
  var maxx = w - (kw*bsize)
  var maxy = h - (kh*bsize)
  var ret: ReturnPos
  for sy = 0, maxy do
    for sx = 0, maxx do
      if check_bin_pos(w, h, src, chan, kw, kh, kernel, bsize, sx, sy) then
        ret.x = sx
        ret.y = sy
        return ret
      end
    end
  end
  ret.x = -1   -- no match
  ret.y = -1
  return ret
end

return m
