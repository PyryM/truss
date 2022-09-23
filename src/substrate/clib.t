-- wrapper around common C includes

local build = require("build/build.t")

return {
  std = build.includec("stdlib.h"),
  io = build.includec("stdio.h"),
  str = build.includec("string.h"),
  math = require("math/cmath.t")
}