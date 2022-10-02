-- math/colorspaces.t
--
-- colorspace conversion functions

local cmath = require("substrate").libc.math

local m = {}

local terra clamp(v: double, minv: double, maxv: double)
  return terralib.select(v < minv, minv, 
          terralib.select(v > maxv, maxv, v))
end

-- lab<->rgb conversions ported from: https://github.com/antimatter15/rgb-lab
-- MIT license
terra m.lab2rgb(lab: &float, rgb: &float, normalize: bool)
  var y: double = (lab[0] + 16.0) / 116.0
  var x: double = lab[1] / 500.0 + y
  var z: double = y - lab[2] / 200.0

  x = 0.95047 * terralib.select(x * x * x > 0.008856, x * x * x, (x - 16.0/116.0) / 7.787)
  y = 1.00000 * terralib.select(y * y * y > 0.008856, y * y * y, (y - 16.0/116.0) / 7.787)
  z = 1.08883 * terralib.select(z * z * z > 0.008856, z * z * z, (z - 16.0/116.0) / 7.787)

  var r = x *  3.2406 + y * -1.5372 + z * -0.4986
  var g = x * -0.9689 + y *  1.8758 + z *  0.0415
  var b = x *  0.0557 + y * -0.2040 + z *  1.0570

  r = terralib.select(r > 0.0031308, 1.055 * cmath.pow(r, 1.0/2.4) - 0.055, 12.92 * r)
  g = terralib.select(g > 0.0031308, 1.055 * cmath.pow(g, 1.0/2.4) - 0.055, 12.92 * g)
  b = terralib.select(b > 0.0031308, 1.055 * cmath.pow(b, 1.0/2.4) - 0.055, 12.92 * b)

  rgb[0] = clamp(r, 0.0, 1.0)
  rgb[1] = clamp(g, 0.0, 1.0)
  rgb[2] = clamp(b, 0.0, 1.0)
  if not normalize then
    for chan = 0, 3 do rgb[chan] = rgb[chan] * 255.0 end
  end
end


terra m.rgb2lab(rgb: &float, lab: &float, normalized: bool)
  var r: double = rgb[0]
  var g: double = rgb[1]
  var b: double = rgb[2]
  if not normalized then
    r = r / 255.0
    g = g / 255.0
    b = b / 255.0
  end

  r = terralib.select(r > 0.04045, cmath.pow((r + 0.055) / 1.055, 2.4), r / 12.92)
  g = terralib.select(g > 0.04045, cmath.pow((g + 0.055) / 1.055, 2.4), g / 12.92)
  b = terralib.select(b > 0.04045, cmath.pow((b + 0.055) / 1.055, 2.4), b / 12.92)

  var x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
  var y = (r * 0.2126 + g * 0.7152 + b * 0.0722) / 1.00000
  var z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883

  x = terralib.select(x > 0.008856, cmath.pow(x, 1.0/3.0), (7.787 * x) + 16.0/116.0)
  y = terralib.select(y > 0.008856, cmath.pow(y, 1.0/3.0), (7.787 * y) + 16.0/116.0)
  z = terralib.select(z > 0.008856, cmath.pow(z, 1.0/3.0), (7.787 * z) + 16.0/116.0)

  lab[0] = (116.0 * y) - 16.0
  lab[1] = 500.0 * (x - y)
  lab[2] = 200.0 * (y - z)
end

-- OKLab <-> srgb is public domain from Björn Ottosson
-- https://bottosson.github.io/posts/oklab/

local terra to_gamma(x: float): float
  x = clamp(x, 0.0, 1.0)
  if x >= 0.0031308 then
    return 1.055 * cmath.powf(x, 1.0/2.4) - 0.055
  else
    return 12.92 * x
  end
end

local terra to_linear(x: float): float
  x = clamp(x, 0.0, 1.0)
  if x >= 0.04045 then
    return cmath.powf((x + 0.055)/(1 + 0.055), 2.4)
  else 
    return x / 12.92
  end
end

terra m.rgbf2oklab(rgb: &float, lab: &float)
  var r = to_linear(rgb[0])
  var g = to_linear(rgb[1])
  var b = to_linear(rgb[2])

  var l: float = 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
	var m: float = 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
	var s: float = 0.0883024619*r + 0.2817188376*g + 0.6299787005*b

  var l_ = cmath.cbrtf(l)
  var m_ = cmath.cbrtf(m)
  var s_ = cmath.cbrtf(s)

  lab[0] = 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_
  lab[1] = 1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_
  lab[2] = 0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
end

terra m.oklab2rgbf(lab: &float, rgb: &float)
  var L = lab[0]
  var a = lab[1]
  var b = lab[2]

  var l_: float = L + 0.3963377774*a + 0.2158037573*b
  var m_: float = L - 0.1055613458*a - 0.0638541728*b
  var s_: float = L - 0.0894841775*a - 1.2914855480*b

  var l = l_*l_*l_
  var m = m_*m_*m_
  var s = s_*s_*s_

  rgb[0] = to_gamma( 4.0767416621*l - 3.3077115913*m + 0.2309699292*s)
  rgb[1] = to_gamma(-1.2684380046*l + 2.6097574011*m - 0.3413193965*s)
  rgb[2] = to_gamma(-0.0041960863*l - 0.7034186147*m + 1.7076147010*s)
end

-- turn    {255,255,255,255} \ 
--      {1.0, 1.0, 1.0, 1.0}  |-> {1,1,1,1}
--                0xFFFFFFFF /
function m.parse_color_to_rgbf(c)
  if type(c) == 'number' then
    local val = {}
    for idx = 1, 4 do
      val[idx] = bit.band(bit.rshift(c, (4-idx)*8), 0xFF)/255.0
    end
    return val
  else -- assume table
    local minval, maxval = math.huge, 0.0
    for _, v in ipairs(c) do
      minval = math.min(minval)
      maxval = math.max(maxval)
    end
    local denom, val = 1, {0,0,0,1}
    if maxval > 1 then
      denom = 255.0
    end
    for idx, v in ipairs(c) do
      val[idx] = v / denom
    end
    return val
  end
end

return m