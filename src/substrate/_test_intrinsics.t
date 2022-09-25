local m = {}

local function test_intrinsic_memops(t)
  local intrinsics = require("substrate/intrinsics.t")

  local T = int32
  local N = 512
  local mem = terralib.new(T[N])
  local mem2 = terralib.new(T[N])
  for idx = 0, N-1 do
    mem[idx] = idx
    mem2[idx] = 0
  end

  local terra memcpy(dest: &T, src: &T, ct: int32)
    intrinsics.memcpy(dest, src, ct * sizeof(T))
  end

  memcpy:disas()

  local terra memmove(dest: &T, src: &T, ct: int32)
    intrinsics.memmove(dest, src, ct * sizeof(T))
  end

  local terra memset(dest: &T, val: int8, ct: int32)
    intrinsics.memset(dest, val, ct * sizeof(T))
  end

  local terra compare(a: &T, b: &T, ct: int32): bool
    for idx = 0, ct do
      if a[idx] ~= b[idx] then return false end
    end
    return true
  end

  memcpy(mem2, mem, N)
  t.ok(compare(mem, mem2, N), "memcopy")
  memset(mem2, 0, N)
  local allzero = true
  for idx = 0, N-1 do
    if mem2[idx] ~= 0 then allzero = false end
  end
  t.ok(allzero, "memset 0")
  memmove(mem2, mem, N)
  t.ok(compare(mem, mem2, N), "memmove")
end

function m.run(test)
  test("intrinsic memory ops", test_intrinsic_memops)
end

return m