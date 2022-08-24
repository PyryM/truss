-- gfx/nanovg.t
--
-- nanovg

local build = require("build/build.t")
local modutils = require("core/module.t")
local class = require("class")
local m = {}

local nanovg_c_raw = build.includec("bgfx/nanovg_terra.h")

local nvg_c_funcs = {}
local nvg_c = {}
local nvg_constants = {}
modutils.reexport_without_prefix(nanovg_c_raw, "nvg", nvg_c_funcs)
modutils.reexport_without_prefix(nanovg_c_raw, "nvg", nvg_c)
modutils.reexport_without_prefix(nanovg_c_raw, "NVG_", nvg_c)
modutils.reexport_without_prefix(nanovg_c_raw, "NVG_", nvg_constants)
m.C = nvg_c
m.C_raw = nanovg_c_raw

-- nvg functions that *don't* take a NVGcontext* as the first argument
local nvg_statics = {
  "RGB", "RGBf", "RGBA", "RGBAf", "LerpRGBA", "TransRGBA", "TransRGBAf", "HSL",
  "HSLA", "TransformIdentity", "TransformTranslate", "DegToRad", "RadToDeg",
  "TransformInverse", "TransformSkewX", "TransformSkewY", "TransformMultiply",
  "TransformPremultiply", "TransformRotate", "TransformPoint", "TransformScale"
}

local NVGContext = class("NVGContext")
m.NVGContext = NVGContext

function NVGContext:init(view, edgeaa)
  self._viewid = (view and view._viewid) or 0
  self._ctx = nvg_c_funcs.CreateC((edgeaa and 1) or 0, self._viewid)
  self._fonts = {}
  self._font_aliases = {}
  self._images = {}
  if view then view:set_sequential(true) end

  self.resources = {} -- a public table to hold context-bound resources (images)
end

function NVGContext:set_view(view)
  self:assert_valid()
  if (not view) or (view._viewid == self._viewid) then return end
  self._viewid = view._viewid
  nvg_c_funcs.SetViewIdC(self._ctx, self._viewid)
  view:set_sequential(true)
end

function NVGContext:assert_valid()
  if not self._ctx then
    error("Nil nvg context!")
  end
end

function NVGContext:get_context_ptr()
  self:assert_valid()
  return self._ctx
end

function NVGContext:load_font(filename, alias)
  self:assert_valid()

  if self._fonts[filename] then
    return self._fonts[filename].id
  end

  if self._font_aliases[alias] then
    error("Font with alias [" .. alias .. "] already exists.")
  end

  local data = truss.read_file_buffer(filename)
  if not data then error("Font didn't exist.") end

  -- final 0 argument indicates that nanovg should not free the data
  -- FIXME: worry about possible memory issues with this! 
  -- Check how occultech handles this!
  local font_id = nvg_c_funcs.CreateFontMem(self._ctx, alias,
                                            data.data, data.size, 0)
  log.debug("Created font with id " .. font_id)
  self._fonts[filename] = {id = font_id, data = data}
  self._font_aliases[alias] = self._fonts[filename]
  return font_id
end


function NVGContext:swap_image(image, filename)
  self:assert_valid()
  if image.handle then
    nvg_c_funcs.DeleteImage(self._ctx, image.handle)
    image.handle = nil
  end
  local imageload = require("./imageload.t")
  local imgdata = imageload.load_image_from_file(filename)
  if imgdata == nil then truss.error("Texture load error: " .. filename) end
  image.handle = nvg_c_funcs.CreateImageRGBA(self._ctx, 
    imgdata.width, imgdata.height, 0, imgdata.data)
  image.w, image.h = imgdata.width, imgdata.height
  image.source = filename
  imageload.release_image(imgdata)
  return image
end

function NVGContext:load_image(filename, alias)
  self:assert_valid()
  alias = alias or filename
  if not self._images[alias] then
    self._images[alias] = self:swap_image({name = alias}, filename)
  end
  return self._images[alias]
end

function NVGContext:delete_image(image)
  self:assert_valid()
  if type(image) == 'string' then image = self._images[image] end
  if not image then truss.error("Tried to release nil image") end
  if not image.handle then truss.error("Image has no handle?") end
  self._images[image.name] = nil
  nvg_c_funcs.DeleteImage(self._ctx, image.handle)
end

-- convenience function to draw an image
function NVGContext:Image(im, x, y, w, h, alpha)
  if type(im) == "string" then
    im = self:load_image(im)
  end
  self:BeginPath()
  w = w or im.w
  h = h or im.h
  local patt = self:ImagePattern(x, y, w, h, 0.0,
                                 im.handle, alpha or 1.0)
  self:FillPaint(patt)
  self:Rect(x, y, w, h)
  self:Fill()
end

function NVGContext:begin_frame(view)
  local w,h = view:get_active_dimensions()
  self.width, self.height = w, h
  self:BeginFrame(w, h, 1.0)
end

function NVGContext:end_frame()
  self:EndFrame()
end

function NVGContext:release()
  if self._ctx then
    nvg_c_funcs.Delete(self._ctx)
    self._ctx = nil
  end
end

-- autogenerate bindings for other functions and constants
-- to allow ctx:whatever(...) and ctx.WHATEVER
local s_table = {}
for _, k in ipairs(nvg_statics) do s_table[k] = true end
-- -- functions
for func_name, func in pairs(nvg_c_funcs) do
  if s_table[func_name] then
    NVGContext[func_name] = function(self, ...)
      return func(...)
    end
  else
    NVGContext[func_name] = function(self, ...)
      return func(self._ctx, ...)
    end
  end
end
-- -- constants
for const_name, val in pairs(nvg_constants) do
  NVGContext[const_name] = val
end

return m
