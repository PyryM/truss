local lazy = require("./lazyload.t")
local exports = {}
local substrate = lazy.lazy_table({}, exports)

local function add_exports(srcmodule)
  local mod = require(srcmodule)
  for _, name in ipairs(mod.exported_names) do
    exports[name] = function() return mod[name] end
  end
end

add_exports("./cfg.t")
add_exports("./array.t")
add_exports("./box.t")

return substrate