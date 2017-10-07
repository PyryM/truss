-- addons/nanovg.t
--
-- nanovg

local modutils = require("core/module.t")
local class = require("class")
local m = {}

local nanovg_c_raw = terralib.includec("nanovg_terra.h")

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
  self._ctx = nvg_c_funcs.Create((edgeaa and 1) or 0, self._viewid)
  self._fonts = {}
  self._font_aliases = {}
  if view then view:set_sequential(true) end

  self.resources = {} -- a public table to hold context-bound resources (images)
end

function NVGContext:set_view(view)
  self:assert_valid()
  if (not view) or (view._viewid == self._viewid) then return end
  self._viewid = view._viewid
  nvg_c_funcs.ViewId(self._ctx, self._viewid)
  view:set_sequential(true)
end

function NVGContext:assert_valid()
  if not self._ctx then
    truss.error("Nil nvg context!")
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
    truss.error("Font with alias [" .. alias .. "] already exists.")
  end

  local data = truss.C.load_file(filename)
  if data == nil then truss.error("Font didn't exist.") end

  -- final 0 argument indicates that nanovg should not free the data
  local font_id = nvg_c_funcs.CreateFontMem(self._ctx, alias,
                                            data.data, data.data_length, 0)
  log.debug("Created font with id " .. font_id)
  self._fonts[filename] = {id = font_id, data = data}
  self._font_aliases[alias] = self._fonts[filename]
  return font_id
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
