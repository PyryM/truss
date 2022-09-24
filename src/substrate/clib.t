-- wrapper around common C includes

local build = require("build/build.t")
local lazy = require("./lazyload.t")

local includers = {}
local headers = {
  std = "stdlib.h",
  io = "stdio.h",
  str = "string.h",
  math = "math.h",
  int = "stdint.h",
}
for name, fn in pairs(headers) do
  includers[name] = function()
    return build.includec(fn)
  end
end

return lazy.lazy_table({}, includers)