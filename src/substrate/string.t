local m = {}
local lazy = require("./lazyload.t")
local util = require("./util.t")

local _built = nil

function m._build(options)
  if _built then return _built end

  log.build("Building string types")

  options = options or {}
  local cfg = options.cfg or require("./cfg.t").configure()
  local size_t = assert(cfg.size_t, "No size_t!")
  local libc = require("./libc.t")

  local char_t = int8
  local StringSlice = require("./array.t").Slice(char_t)
  local String = require("./array.t")._Array(char_t, {
    cfg = cfg, slice_t = StringSlice
  })

  local terra wrap_c_str(str: &int8): StringSlice
    return StringSlice{
      data = [&char_t](str),
      size = libc.string.strlen(str)
    }
  end

  terra String:copy_cstr(str: &int8)
    var slice = wrap_c_str(str)
    self:copy_slice(&slice)
  end

  local as_string_slice = macro(function(arr)
    return `StringSlice{data = [&char_t](arr.data), size = arr:size_bytes()}
  end)

  _built = {
    String = String,
    StringSlice = StringSlice,
    wrap_c_str = wrap_c_str,
    as_string_slice = as_string_slice
  }

  return _built
end

local lazy_items = {
  String = function() return m._build().String end,
  StringSlice = function() return m._build().StringSlice end,
  wrap_c_str = function() return m._build().wrap_c_str end,
  as_string_slice = function() return m._build().as_string_slice end,
}
  
m.exported_names = {
  "String", "StringSlice", "wrap_c_str", "as_string_slice"
}

return lazy.lazy_table(m, lazy_items)