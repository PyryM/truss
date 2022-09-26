local libc = require("substrate/libc.t")

local terra x_div_x(x: uint32): uint32
  var y = x/x
  if x == 0 then
    libc.io.printf("Got zero!\n")
  end
  return y
end

local function init()
  log.info("x_div_x(0)", x_div_x(0))
  x_div_x:disas()
end

return {init = init}