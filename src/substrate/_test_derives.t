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

  t.try(function()
    local mathtypes = require("math/types.t")
    local cmath = require("substrate").libc.math
    local matrix = require("math/matrix.t")

    local vec4 = mathtypes.vec4_
    local MAX_IDATA = 4
    local MAX_KINDS = 4

    local struct PileNode {
      --tf: mathtypes.mat4_;
      data: float[MAX_IDATA * 4];
      bound_center: vec4;
      bound_scale: float;
      next_kindred: &PileNode;
      kind: uint32;
      visible: bool;
      active: bool;
    }

    substrate.derive.derive_init(PileNode)

    terra PileNode:copy(rhs: &PileNode)
      @self = @rhs
    end

    terra PileNode:release()
      -- nothing to do
    end

    -- This is necessary for some reason!
    PileNode:complete()

    local struct Pile {
      head: &PileNode;
      tail: &PileNode;
      count: uint32;
      datacount: uint32;
      base_radius: float;
      --frustum: Frustum;
    }

    local struct InstancePile {
      nodes: substrate.Array(PileNode);
      free_list: substrate.Array(uint32);
      working_set: substrate.Array(&PileNode);
      working_kind: uint32;
      max_allocated: uint32;
      n_free: uint32;
      piles: Pile[MAX_KINDS];
    }

    return InstancePile
  end, "Regression from microgfx compiles")
end

function m.run(test)
  test("derives", test_derives)
end

return m