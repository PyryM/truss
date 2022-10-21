-- native/tga.t
--
-- terra targa reading/writing

local substrate = require("substrate")
local ByteArray = substrate.ByteArray
local StringSlice = substrate.StringSlice
local wrap_c_str = substrate.wrap_c_str
local c = substrate.libc
local cfg = substrate.configure()
local LOG = cfg.LOG

local m = {}

local struct TGAHeader {
  idlength: uint8;
  colourmaptype: uint8;
  datatypecode: uint8;
  nonsense: uint8[5];
  x_origin: uint16;
  y_origin: uint16;
  width: uint16;
  height: uint16;
  bitsperpixel: uint8;
  imagedescriptor: uint8;
}

local struct TGAImage {
  width: uint32;
  height: uint32;
  bytes_per_pixel: uint32;
  data: ByteArray;
}

terra TGAImage:init()
  self.width = 0
  self.height = 0
  self.data:init()
end

terra TGAImage:_invalidate(): bool
  self.width = 0
  self.height = 0
  self.data:release()
  return false
end

terra TGAImage:release()
  self:_invalidate()
end

local function check_bounds(pos, len, req)
  return quote
    if pos + req > len then
      [LOG("TGA bound check error! %d + %d > %d", pos, req, len)]
      return false 
    end
  end
end

terra TGAImage:_decode_rle(src: &uint8, srclen: uint32): bool
  var bytes_per_pixel = self.bytes_per_pixel
  var dest_data = self.data.data
  var destpos: uint32 = 0
  var total_bytes = self.data.capacity
  var srcpos: uint32 = 0
  while (destpos < total_bytes) and (srcpos < srclen) do
    var header: uint8 = src[srcpos]
    var count: uint8 = (header and 0x7F) + 1
    srcpos = srcpos + 1
    if (header and 0x80) > 0 then
      -- RLE 'packet'
      [check_bounds(srcpos, srclen, bytes_per_pixel)]
      var color: uint8[4]
      for chan = 0, bytes_per_pixel do
        color[chan] = src[srcpos + chan]
      end
      srcpos = srcpos + bytes_per_pixel
      [check_bounds(destpos, total_bytes, `count*4)]
      for i = 0, count do
        for chan = 0, bytes_per_pixel do
          dest_data[destpos+chan] = color[chan]
        end
        destpos = destpos + 4
      end
    else
      -- raw 'packet'
      [check_bounds(destpos, total_bytes, `count*4)]
      [check_bounds(srcpos, srclen, `count*bytes_per_pixel)]
      for i = 0, count do
        for chan = 0, bytes_per_pixel do
          dest_data[destpos+chan] = src[srcpos+chan]
        end
        destpos = destpos + 4
        srcpos = srcpos + bytes_per_pixel
      end
    end
  end
  return true
end

terra TGAImage:_decode_uncompressed(src: &uint8, srclen: uint32): bool
  var bytes_per_pixel = self.bytes_per_pixel
  var dest_data = self.data.data
  for y = 0, self.height do
    for x = 0, self.width do
      for chan = 0, bytes_per_pixel do
        dest_data[chan] = src[chan]
      end
      src = src + bytes_per_pixel
      dest_data = dest_data + 4
    end
  end
  return true
end

terra TGAImage:parse(src: &ByteArray): bool
  if src.datasize < sizeof(TGAHeader) then
    return self:_invalidate()
  end
  -- is this cast safe? dunno
  var header: &TGAHeader = [&TGAHeader](src.data)
  if (header.datatypecode ~= 2) and (header.datatypecode ~= 10) then
    c.io.printf("Unsupported TGA type: %d\n", header.datatypecode)
    return self:_invalidate()
  end
  if header.colourmaptype ~= 0 then
    c.io.printf("Colormaps not supported.\n")
    return self:_invalidate()
  end
  self.width = header.width
  self.height = header.height
  if (header.bitsperpixel % 8 ~= 0) or (header.bitsperpixel > 32) then
    c.io.printf("Unsupported BPP: %d\n", header.bitsperpixel)
    return self:_invalidate()
  end
  var bytes_per_pixel = header.bitsperpixel / 8
  self.bytes_per_pixel = bytes_per_pixel
  var src_size: uint32 = self.width * self.height * bytes_per_pixel
  var req_size: uint32 = src_size + sizeof(TGAHeader) + header.idlength

  self.data:allocate(self.width * self.height * 4) -- always output RGBA
  self.data:fill(self.data.capacity, 255)

  var image_data_size: int32 = src.datasize - (sizeof(TGAHeader) + header.idlength)
  var image_data: &uint8 = src.data + (sizeof(TGAHeader) + header.idlength)

  if header.datatypecode == 2 then
    if req_size > src.datasize then
      c.io.printf("Source is too small! %d > %d\n", req_size, src.datasize)
      return self:_invalidate()
    end
    return self:_decode_uncompressed(image_data, image_data_size)
  elseif header.datatypecode == 10 then
    return self:_decode_rle(image_data, image_data_size)
  else
    c.io.printf("Somehow got here? Invalid datatype.\n")
    return false
  end
end

terra TGAImage:flip_vertical()
  var ipos: uint32 = 0
  var mid: uint32 = self.height / 2
  var rowsize: uint32 = self.width*4
  var data: &uint8 = self.data.data
  for r = 0, mid do
    var mirror_row = self.height - 1 - r
    var p0 = r*rowsize
    var p1 = mirror_row*rowsize
    for c = 0, rowsize do
      var a,b = p0+c, p1+c
      data[a], data[b] = data[b], data[a]
    end
  end
end

m.TGAImage = TGAImage

return m