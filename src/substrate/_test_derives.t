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

  local struct Recursive {
    value: uint32;
    sibling: &Recursive;
  }

  terra Recursive:release()
    -- nothing to do
  end

  t.try(function()
    local terra test(v: &Recursive, ct: uint32)
      [derive.release_array_contents(`v, `ct)]
    end
  end, "Was able to derive array release for recursive type")
end

function m.run(test)
  test("derives", test_derives)
end

return m