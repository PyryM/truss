-- a sidebar for manipulating settings
-- heavily inspired by 'dat.gui'

local class = require("class")
local IG = require("gfx/imgui.t").C
local m = {}

local KINDS = {}

local function gen_slider(finfo, field_q, io_q)
  local label = assert(finfo.label or finfo.name)
  local v_min, v_max = unpack(finfo.limits)
  local format = assert(finfo.format)
  local flags = finfo.flags
  local Slider = finfo.slider_func
  return quote 
    Slider(label, &field_q, v_min, v_max, format, flags)
  end
end

local function gen_checkbox(finfo, field_q, io_q)
  local label = assert(finfo.label or finfo.name)
  return quote IG.Checkbox(label, &field_q) end
end

local function gen_button(finfo, field_q, io_q)
  local label = assert(finfo.label or finfo.name)
  return quote
    if IG.Button(label, IG.Vec2{0.0, 0.0}) then
      field_q = field_q + 1
    end
  end
end

local function gen_divider(finfo, io_q)
  return quote IG.Separator() end
end

local function gen_label(finfo, io_q)
  local label = assert(finfo.label or finfo.name)
  return quote IG.Text("%s", label) end
end

KINDS["int"] = {
  ctype = int32, default = 0, gen_draw = gen_slider,
  limits = {0, 100}, format = "%d", 
  slider_func = IG.SliderInt, flags = IG.SliderFlags_None
}

KINDS["float"] = {
  ctype = float, default = 0, gen_draw = gen_slider,
  limits = {0, 100}, format = "%.4f", 
  slider_func = IG.SliderFloat, flags = IG.SliderFlags_None
}

KINDS["bool"] = {ctype = bool, default = false, gen_draw = gen_checkbox}
KINDS["button"] = {ctype = int32, default = 0, gen_draw = gen_button}
KINDS["divider"] = {ctype = nil, gen_draw = gen_divider}
KINDS["label"] = {ctype = nil, gen_draw = gen_label}

local BAR_DEFAULTS = {
  title = "Settings", open = true
}

local DatabarBuilder = class("DatabarBuilder")
m.DatabarBuilder = DatabarBuilder

function DatabarBuilder:init(options)
  options = truss.extend_table({}, BAR_DEFAULTS, options or {})
  self._ordered_fields = {}
  self._named_fields = {}
  self._options = options
end

function DatabarBuilder:field(options)
  local name = options[1] or options.name
  local kind = options[2] or options.kind or name -- to avoid {"divider", "divider"}
  local kind_info = KINDS[kind]
  if not kind_info then
    truss.error("Unknown Databar field kind: " .. kind)
  end
  local finfo = truss.extend_table({}, kind_info, options)
  finfo.name = name
  if finfo.ctype then
    if self._named_fields[name] then
      truss.error("Field " .. name .. " added multiple times!")
    end
    self._named_fields[name] = finfo
  end
  table.insert(self._ordered_fields, finfo)
  return self
end

function DatabarBuilder:divider()
  table.insert(self._ordered_fields, {gen_draw=gen_divider})
end

function DatabarBuilder:build_c()
  local DataState = terralib.types.newstruct()
  DataState.entries = {}
  for fname, finfo in pairs(self._named_fields) do
    table.insert(DataState.entries, {fname, finfo.ctype})
  end
  table.insert(DataState.entries, {"_bar_open", bool})
  table.insert(DataState.entries, {"_bar_visible", bool})

  local _self = self
  terra DataState:init()
    self._bar_open = [_self._options.open]
    self._bar_visible = true
    escape
      for fname, finfo in pairs(_self._named_fields) do
        if finfo.gen_init then
          emit(finfo:gen_init(`self.[fname], `io))
        else
          emit(quote self.[finfo.name] = [finfo.default] end)
        end
      end
    end
  end

  local title = assert(self._options.title)
  terra DataState:draw()
    if not self._bar_visible then return end
    var io = IG.GetIO()
    escape
      local x, y = _self._options.x, _self._options.y
      local w, h = _self._options.width, _self._options.height
      if x and y then
        emit(quote 
          IG.SetNextWindowPos(IG.Vec2{x, y}, IG.Cond_FirstUseEver, IG.Vec2{0, 0})
        end)
      end
      if w and h then
        emit(quote
          IG.SetNextWindowSize(IG.Vec2{w, h}, IG.Cond_FirstUseEver)
        end)
      end
    end
    IG.SetNextWindowCollapsed(not self._bar_open, IG.Cond_FirstUseEver)
    var close_flag: &bool = nil
    escape if _self._options.allow_close then 
      emit(quote close_flag = &(self._bar_visible) end)
    end end
    if not IG.Begin(title, close_flag, IG.WindowFlags_None) then
      IG.End()
      return
    end
    escape
      for idx, finfo in ipairs(_self._ordered_fields) do
        if _self._named_fields[finfo.name] then
          emit(finfo:gen_draw(`self.[finfo.name], `io))
        else
          -- a stateless field like a divider or label
          emit(finfo:gen_draw(`io))
        end
      end
    end
    IG.End()
  end

  terra DataState:set_visible(visible: bool)
    self._bar_visible = visible
  end

  return DataState
end

function DatabarBuilder:build()
  local ctype = self:build_c()
  local state_val = terralib.new(ctype)
  state_val:init()
  return state_val
end

return m