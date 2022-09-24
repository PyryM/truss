local lazy = require("./lazyload.t")
local exports = {}
local substrate = lazy.lazy_table({}, exports)

local function add_exports(srcmodule, names)
  for _, name in ipairs(names) do
    exports[name] = function()
      return require(srcmodule)[name]
    end
  end
end

add_exports("./array.t", {"Slice", "Array"})

return substrate