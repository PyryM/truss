local m = {}

local function test_derives(t)
  local substrate = require("substrate")
  local derive = substrate.derive

  local struct Arraylike {
    capacity: substrate.configure().size_t;
    data: &int32;
  }
  derive.derive_init(Arraylike)

  local isnull = terralib.memoize(function(T)
    return terra(v: &T)
      return v == nil
    end
  end)

  local foo = terralib.new(int32[10])

  local temp = terralib.new(Arraylike)
  temp.capacity = 10
  temp.data = foo

  temp:init()
  t.expect(temp.capacity, 0ULL, "After init capacity is 0")
  t.ok(isnull(int32)(temp.data), "After init data ptr is null")
end

function m.run(test)
  test("derives", test_derives)
end

return m