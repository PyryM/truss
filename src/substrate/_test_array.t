local m = {}

local function test_arrays(jape)
  local test, expect = jape.test, jape.expect
  local substrate = require("substrate")
  local libc = require("substrate/libc.t")

  local IntVec = substrate.Vec(int32)
  local terra check_bytes(v: &IntVec, cmp: &int32, n: uint32): bool
    var bb = v:as_bytes()
    if bb.size ~= sizeof(int32)*n then 
      libc.io.printf("Wrong size!\n")
      return false 
    end
    var dd = [&uint8](cmp)
    for idx = 0, bb.size do
      if bb.data[idx] ~= dd[idx] then 
        libc.io.printf("Byte mismatch @%d: %d vs %d!\n", idx, bb.data[idx], dd[idx])
        return false 
      end
    end
    return true
  end

  local v
  jape.before_each(function()
    v = terralib.new(IntVec)
    v:init()
    v:push_val(11)
    v:push_val(12)
    v:push_val(13)
  end)

  jape.after_each(function()
    v:release()
    v = nil
  end)

  test("pushing", function()
    expect(v.size):to_be(3)
    expect(v.data[0]):to_be(11)
    expect(v.data[1]):to_be(12)
    expect(v.data[2]):to_be(13)
  end)

  test("bytes", function()
    local temp = terralib.new(int32[3])
    temp[0], temp[1], temp[2] = 11, 12, 13
    expect(check_bytes(v, temp, 3)):to_be_truthy()
  end)

  test("clearing", function()
    v:clear()
    v:push_val(111)
    expect(v.size):to_be(1)
    expect(v.data[0]):to_be(111)
  end)
end

function m.init(jape)
  (jape or require("dev/jape.t")).describe("arrays", test_arrays)
end

return m