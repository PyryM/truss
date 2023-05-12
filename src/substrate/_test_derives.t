local m = {}

local function test_derives(jape)
  local substrate = require("substrate")
  local derive = substrate.derive
  local test, expect = jape.test, jape.expect

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

  test("derive inits", function()
    local foo = terralib.new(int32[10])
    local temp = terralib.new(Arraylike)
    temp.capacity = 10
    temp.data = foo

    temp:init()
    expect(temp.capacity):to_be(0ULL)
    expect(isnull(int32)(temp.data)):to_be_truthy()
  end)

  local struct Recursive {
    value: uint32;
    sibling: &Recursive;
  }

  terra Recursive:release()
    -- nothing to do
  end

  test("derive on recursive type", function()
    expect(function()
      local terra test(v: &Recursive, ct: uint32)
        [derive.release_array_contents(`v, `ct)]
      end
    end):_not():to_throw()
  end)

  test("microgfx regression", function()
    expect(function()
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
    end):_not():to_throw()
  end)

  test("recursive struct dump", function()
    expect(function()
      local struct Foo {
        a: float;
      }
      terra Foo:dump()
        substrate.libc.io.printf("FOO!\n")
      end
      local struct VecEh {
        x: float;
        y: float;
        z: float;
      }
      local struct LineEh {
        p0: VecEh;
        p1: VecEh;
        f: Foo;
      }
      derive.derive_dump(LineEh)
      local testo = terralib.new(LineEh)
      testo.p0.x = 1.0
      testo.p0.y = 2.0
      testo.p0.z = 3.0
      testo.p1.x = 4.0
      testo.p1.y = 5.0
      testo.p1.z = 6.0
      testo.f.a = 12.0
      testo:dump()
    end):_not():to_throw()
  end)
end

function m.init(jape)
  (jape or require("dev/jape.t")).describe("derives", test_derives)
end

return m