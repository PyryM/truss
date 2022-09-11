-- tests potential struct passing issue on arm64

local m = {}

function m.run(test)
  test("struct passing", m.test_struct_passing)
  test("minimal struct passing", m.minimal_struct_pass)
end

function m.minimal_struct_pass(t)
  local cdefs = terralib.includecstring[[
  typedef struct Color {
    float rgba[4];
  } Color;
  ]]

  local terra new_color(): cdefs.Color
    var ret: cdefs.Color
    for idx = 0, 4 do ret.rgba[idx] = [float](idx) end
    return ret
  end

  local val = new_color()
  t.expect(val.rgba[2], 2.0, "Color.b is as expected")
end

function m.test_struct_passing(t)
  local cdefs = terralib.includecstring[[
  typedef struct Color1 {
    float rgba[4];
  } Color1;

  typedef struct Color2 {
    union {
      float rgba[4];
      struct {
        float r,g,b,a;
      };
    };
  } Color2;
  ]]

  if t.verbose then
    print(cdefs.Color2:layoutstring())
  end

  local function run_tests(name, ctype, rgba_get)
    local terra create_ctype(): ctype
      var ret: ctype
      for idx = 0, 4 do
        [rgba_get(ret)][idx] = [float](idx) + 1.0
      end
      return ret
    end

    local terra copy_ctype(src: ctype): ctype
      var ret: ctype
      for idx = 0, 4 do
        [rgba_get(ret)][idx] = [rgba_get(src)][idx] + 1.0
      end
      return ret
    end

    local terra get_elem(src: &ctype, idx: uint32): float
      return [rgba_get(src)][idx]
    end

    local terra set_elem(src: &ctype, idx: uint32, val: float)
      [rgba_get(src)][idx] = val
    end

    local function tolist(s)
      local ret = {}
      for idx = 0, 3 do
        ret[idx+1] = get_elem(s, idx)
      end
      return ret
    end

    if t.verbose then
      copy_ctype:disas()
    end

    local val = create_ctype()
    t.expect(tolist(val), {1.0, 2.0, 3.0, 4.0}, name .. " returned struct by val")
    local val2 = copy_ctype(val)
    set_elem(val, 2, 1000.0)
    t.expect(tolist(val2), {2.0, 3.0, 4.0, 5.0}, name .. " accepted struct by val")
  end

  run_tests("struct of array",
    cdefs.Color1, 
    function(q)
      return `q.rgba
    end
  )
  run_tests("struct of union",
    cdefs.Color2, 
    function(q)
      return `q._0.rgba
    end
  )
end

return m