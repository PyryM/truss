-- io/imagewrite.t
--
-- basic (pure lua/terra) image writing uncompressed images

local m = {}

struct m.TGAHeader {
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

function m.create_tga(width, height, data, dest_buff)
  local header = terralib.new(m.TGAHeader)
  header.idlength = 0
  header.colourmaptype = 0
  header.datatypecode = 2 -- uncompressed rgba
  for i = 0,4 do header.nonsense[i] = 0 end
  header.x_origin = 0
  header.y_origin = 0
  header.width = width
  header.height = height
  header.bitsperpixel = 32
  header.imagedescriptor = 8 -- alpha??
  local dsize = (width * height * 4) + 100
  local bb = dest_buff or require("util/string.t").ByteBuffer(dsize)
  bb:append_struct(header, sizeof(m.TGAHeader))
  bb:append_bytes(data, width*height*4)
  return bb
end

function m.flip_rgba_vertical(width, height, data)
  local ipos = 0
  local mid = math.floor(height / 2)
  local rowsize = width*4
  for r = 0,mid do
    local r_mirrored = (height - 1) - r
    local p0 = r*width*4
    local p1 = r_mirrored*width*4
    for c = 0,rowsize do
      local a,b = p0+c, p1+c
      data[a], data[b] = data[b], data[a]
    end
  end
end

function m.write_tga(width, height, data, filename)
  local bb = m.create_tga(width, height, data)
  --bb:write_to_file(filename)
  -- HACK: use Lua IO
  local outfile = io.open(filename, "wb")
  local data = ffi.string(bb._data, bb._cur_size)
  outfile:write(data)
  outfile:close()  
end

return m
