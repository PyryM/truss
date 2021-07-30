-- wrapper around common C includes

return {
  std = terralib.includec("stdlib.h"),
  io = terralib.includec("stdio.h"),
  str = terralib.includec("string.h"),
  math = require("math/cmath.t")
}