local bit = require("bit")
local libc = require("substrate/libc.t")

local terra bin_long_div(_n: uint32, _d: uint32): {uint32, uint32}
  var n: uint64 = _n
  var d: uint64 = _d

  var q: uint64 = 0
  for k = 32, 0, -1 do
    var qq = d << (k - 1)
    if n >= qq then
      n = n - qq
      q = q + (1 << (k - 1))
    end
  end

  libc.io.printf("q: %d, r: %d\n", q, n)
  libc.io.printf("gt: q: %d, r: %d\n", _n / _d, _n % _d)

  return [uint32](q), [uint32](n)
end

local function init()
  local n = 2^32-1
  local d = 1345
  bin_long_div(n, d)
end

return {init = init}