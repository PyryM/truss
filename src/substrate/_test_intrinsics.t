local m = {}

local function build_memops(T)
  local intrinsics = require("substrate/intrinsics.t")
  local ops = {}
  terra ops.memcpy(dest: &T, src: &T, ct: int32)
    intrinsics.memcpy(dest, src, ct * sizeof(T))
  end

  terra ops.memmove(dest: &T, src: &T, ct: int32)
    intrinsics.memmove(dest, src, ct * sizeof(T))
  end

  terra ops.memset(dest: &T, val: int8, ct: int32)
    intrinsics.memset(dest, val, ct * sizeof(T))
  end

  terra ops.compare(a: &T, b: &T, ct: int32): bool
    for idx = 0, ct do
      if a[idx] ~= b[idx] then return false end
    end
    return true
  end

  return ops
end

local function test_intrinsic_memops(t)
  local T = int32
  local N = 512
  local mem = terralib.new(T[N])
  local mem2 = terralib.new(T[N])
  for idx = 0, N-1 do
    mem[idx] = idx
    mem2[idx] = 0
  end

  local ops = build_memops(T)

  ops.memcpy(mem2, mem, N)
  t.ok(ops.compare(mem, mem2, N), "memcopy")
  ops.memset(mem2, 0, N)
  local allzero = true
  for idx = 0, N-1 do
    if mem2[idx] ~= 0 then allzero = false end
  end
  t.ok(allzero, "memset 0")
  ops.memmove(mem2, mem, N)
  t.ok(ops.compare(mem, mem2, N), "memmove")
end

local function gen_memops_tests(T, N)
  N = N or 512
  local ops = build_memops(T)
  local terra main(argv: int, argc: &&int8): int
    var mem: T[N]
    var mem2: T[N]
    for idx = 0, N do
      mem[idx] = idx
      mem2[idx] = 0
    end
    ops.memcpy(&mem2[0], &mem[0], N)
    if not ops.compare(mem, mem2, N) then return 1 end
    if true then return 0 end
    ops.memset(mem2, 0, N)
    for idx = 0, N do 
      if mem2[idx] ~= 0 then return 1 end
    end
    ops.memmove(mem2, mem, N)
    if not ops.compare(mem, mem2, N) then return 1 end
    return 0
  end
  return main
end

local function test_intrinsic_compiled(t)
  t.try(function()
    local testutils = require("dev/testutils.t")
    local memtest = gen_memops_tests(int32, 512)
    testutils.build_and_run_test("intrinsic_memops", memtest)
  end, "Compiled intrinsic memory ops")
end

function m.run(test)
  test("intrinsic memory ops", test_intrinsic_memops)
  test("intrinsic compiled memory ops", test_intrinsic_compiled)
end

return m