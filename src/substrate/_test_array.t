local m = {}

local function test_basic(t)
  local substrate = require("substrate")
  local libc = require("substrate/libc.t")

  local IntVec = substrate.Vec(int32)
  local v = terralib.new(IntVec)
  v:init()
  t.ok(v.size == 0, "New vec has zero length")
  v:push_val(11)
  v:push_val(12)
  v:push_val(13)
  t.ok(v.size == 3, "Vec now has three things")
  t.expect(v.data[0], 11, "1st pushed is correct")
  t.expect(v.data[1], 12, "2nd pushed is correct")
  t.expect(v.data[2], 13, "3rd pushed is correct")

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

  local temp = terralib.new(int32[3])
  temp[0], temp[1], temp[2] = 11, 12, 13
  t.ok(check_bytes(v, temp, 3), "Bytes are right")

  v:clear()
  v:push_val(111)
  t.ok(v.size == 1, "Vec now has 1 thing")
  t.expect(v.data[0], 111, "New 1st elem is correct")

  v:release()
  t.ok(true, "We released a vector without crashing.")
end

function m.run(test)
  test("vector basic", test_basic)
end

return m