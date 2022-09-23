local m = {}
local vector = require("./vector.t")
local c = require("./clib.t")

local function test_basic(t)
  local IntVec = vector.vec(int32)
  local v = terralib.new(IntVec)
  v:init()
  t.ok(v:length() == 0, "New vec has zero length")
  v:push(11)
  v:push(12)
  v:push(13)
  t.ok(v:length() == 3, "Vec now has three things")
  t.expect(v.data[0], 11, "1st pushed is correct")
  t.expect(v.data[1], 12, "2nd pushed is correct")
  t.expect(v.data[2], 13, "3rd pushed is correct")

  local terra check_bytes(v: &IntVec, cmp: &int32, n: uint32): bool
    var bb = v:get_raw_bytes(0, v:length())
    if bb._1 ~= sizeof(int32)*n then 
      c.io.printf("Wrong size!\n")
      return false 
    end
    var dd = [&uint8](cmp)
    for idx = 0, bb._1 do
      if bb._0[idx] ~= dd[idx] then 
        c.io.printf("Byte mismatch @%d: %d vs %d!\n", idx, bb._0[idx], dd[idx])
        return false 
      end
    end
    return true
  end

  local temp = terralib.new(int32[3])
  temp[0], temp[1], temp[2] = 11, 12, 13
  t.ok(check_bytes(v, temp, 3), "Bytes are right")

  v:clear()
  v:push(111)
  t.ok(v:length() == 1, "Vec now has 1 thing")
  t.expect(v.data[0], 111, "New 1st elem is correct")
end

function m.run(test)
  test("vector basic", test_basic)
end

return m