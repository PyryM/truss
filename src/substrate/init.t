local lazy = require("./lazyload.t")
local exports = {}
local substrate = lazy.lazy_table({}, exports)

local function add_exports(srcmodule)
  local mod = require(srcmodule)
  for _, name in ipairs(mod.exported_names) do
    assert(not exports[name], "Duplicate export: " .. name)
    exports[name] = function() return mod[name] end
  end
end

local function add_namespace(srcmodule, name)
  assert(not exports[name], "Duplicate export: " .. name)
  exports[name] = function() return require(srcmodule) end
end

add_exports("./cfg.t")
add_exports("./array.t")
add_exports("./box.t")
add_exports("./string.t")
add_exports("./file.t")
add_namespace("./libc.t", "libc")
add_namespace("./intrinsics.t", "intrinsics")
add_namespace("./derive.t", "derive")

return substrate