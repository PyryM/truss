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

function m.create_tga(imWidth, imHeight, imData, bbDest)
    local header = terralib.new(m.TGAHeader)
    header.idlength = 0
    header.colourmaptype = 0
    header.datatypecode = 2 -- uncompressed rgba
    for i = 0,4 do header.nonsense[i] = 0 end
    header.x_origin = 0
    header.y_origin = 0
    header.width = imWidth
    header.height = imHeight
    header.bitsperpixel = 32
    header.imagedescriptor = 8 -- alpha??
    local dsize = (imWidth * imHeight * 4) + 100
    local bb = bbDest or require("util/string.t").ByteBuffer(dsize)
    bb:append_struct(header, sizeof(m.TGAHeader))
    bb:append_bytes(imData, imWidth*imHeight*4)
    return bb
end

function m.flipRGBAVertical(imW, imH, imData)
    local ipos = 0
    local mid = math.floor(imH / 2)
    local rowsize = imW*4
    for r = 0,mid do
        local rMirrored = imH - r
        local p0 = r*imW*4
        local p1 = rMirrored*imW*4
        for c = 0,rowsize do
            local a,b = p0+c, p1+c
            imData[a], imData[b] = imData[b], imData[a]
        end
    end
end

function m.write_tga(imW, imH, imData, filename)
    local bb = m.create_tga(imW, imH, imData)
    bb:write_to_file(filename)
end

return m
