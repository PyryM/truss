local m = {}

-- require("substrate").configure{
--   allocator = "leaky_allocator"
-- }

local gen = require("./gen.t")
local parser = require("./schemaparser.t")

local buff = nil
local function allocate_buff()
  if not buff then
    buff = terralib.new(gen.CombBuffer)
    buff:init()
    -- the markers should automatically resize so allocating zero is OK?
    buff:allocate(1000000, 0)
  end
  buff:clear()
  return buff
end

local function as_hex(b)
  local frags = {}
  for idx = 0, math.min(tonumber(b.len), tonumber(b.pos))-1 do
    table.insert(frags, ("%02x"):format(b.data[idx]))
  end
  return table.concat(frags, "")
end

local function from_hex(buff, hexstr)
  local nbytes = #hexstr / 2
  for p = 0, nbytes-1 do
    local bytestr = hexstr:sub(p*2+1, p*2+2)
    buff.data[p] = tonumber(bytestr, 16)
  end
  buff.len = nbytes
  buff.pos = 0
end

local function hex_to_bytes(hexstr)
  if not hexstr then return "" end
  local frags = {}
  local nbytes = #hexstr / 2
  for p = 0, nbytes - 1 do
    local bytestr = hexstr:sub(p*2+1, p*2+2)
    table.insert(frags, string.char(tonumber(bytestr, 16)))
  end
  return table.concat(frags)
end

local function hex_equal(buff, hexstr)
  return as_hex(buff) == hexstr
end

local function test_parser(t)
  local ehproto = [[
  enum Eh {
    EH_ZERO = 0;
    EH_TWELVE = 12;
  }
  ]]

  local proto = [[
  // comment type 1
  /* comment type 2 */
  /* message Commented {
    bool one = 1;
  }*/

  syntax = "proto3";

  import "ehproto.proto";

  message Bag {
    message Nested {
      bool loop = 1;
    }

    bool one = 1;
    //Commented two = 2;
    bytes three = 3;
    Eh four = 4;
  }

  message OneOf {
    oneof content {
      bool a = 1;
      bytes b = 2;
    }
    bool c = 3;
  }

  message Thinger {
    repeated AllFloat two = 2;
  }
  ]]
  local schemas, constants = parser.parse(proto, {
    import_resolver = function(path) 
      print("Importing:", path)
      return ehproto 
    end
  })
  t.expect(schemas, {
    Eh = {
      name = "Eh",
      is_enum = true
    },
    Bag = {
      name = "Bag",
      fields = {
        {name = "one", kind = "bool", idx = 1},
        {name = "three", kind = "bytes", idx = 3},
        {name = "four", kind = "enum", idx = 4},
      }
    },
    Thinger = {
      name = "Thinger",
      fields = {
        {name = "two", kind = "AllFloat", repeated = true, idx = 2}
      }
    },
    Nested = {
      name = "Nested",
      fields = {
        {name = "loop", kind = "bool", idx = 1}
      }
    },
    OneOf = {
      name = "OneOf",
      fields = {
        {name = "a", kind = "bool", idx = 1, boxed = true},
        {name = "b", kind = "bytes", idx = 2, boxed = true},
        {name = "c", kind = "bool", idx = 3},
      }
    }
  })
end

local function test_fundamentals(t)
  local function assert_buff_eq(src, target, msg)
    t.expect(as_hex(src), target, msg)
  end

  local buff = allocate_buff()
  local examples = {
    {0, '00'},
    {127, '7f'},
    {128, '8001'},
    {300, 'ac02'}, -- 1010 1100 0000 0010
    {2^21, '80808001'},
    -- Note this must be -1LL for *reasons*
    {-1LL, 'ffffffffffffffffff01'},
    { 9223372036854775806ULL, 'feffffffffffffff7f'},
    {18446744073709551615ULL, 'ffffffffffffffffff01'}
  }
  for _, p in ipairs(examples) do
    local raw, encoded = unpack(p)
    buff:clear()
    local nwritten = buff.buff:write_varint_u64(raw)
    local name = tostring(raw)
    t.ok(nwritten > 0, "varint encoding of " .. name .. " : wrote >0 bytes")
    assert_buff_eq(buff.buff, encoded, "varint encoding of " .. name .. ": correct value")
    buff.buff.pos = 0
    local decoded = buff.buff:read_varint_u64()
    --t.expect(decoded, raw + 0ULL, "varint decoding")
  end
end

local function reset_msgs()
  for _, msg in pairs(msgs) do
    msg.cmsg:clear()
  end
end

local set_fields

local function push_list(cmsg, fname, vals)
  --cmsg[fname]:clear() -- ????
  if #vals == 0 then return end
  if type(vals[1]) == 'table' then
    for _, v in ipairs(vals) do
      local ref = cmsg[fname]:push_new()
      set_fields(ref, v)
    end
  elseif type(vals[1]) == 'string' then
    for _, v in ipairs(vals) do
      local ref = cmsg[fname]:push_new()
      ref:from_string(v, #v)
    end
  else
    for _, v in ipairs(vals) do
      cmsg[fname]:push_val(v)
    end
  end
end

set_fields = function(cmsg, fields)
  for fname, fval in pairs(fields) do
    if type(fval) == 'string' then
      cmsg[fname]:from_string(fval, #fval)
    elseif type(fval) == 'table' and #fval > 0 then
      push_list(cmsg, fname, fval)
    elseif type(fval) == 'table' then
      set_fields(cmsg[fname], fval)
    else
      cmsg[fname] = fval
    end
  end
end

local function test_primitives(t)
  local function assert_buff_eq(src, target, msg)
    t.expect(as_hex(src), target, msg)
  end

  local buff = allocate_buff()

  local pg = gen.ProtoGen()
  pg:add_schema_file("src/protobuf/testgen/test.proto")

  local NestSimple = pg:get("NestSimple")
  print(NestSimple.ctype.methods.clear:prettystring())

  local TESTED_TYPES = {"AllInt", "AllFloat", "AllBag", "Mixed", 
                        "RepeatSimple", "RepeatMixed", "NestSimple"}
  local msgs = {}
  for _, mname in ipairs(TESTED_TYPES) do
    local T = pg:get(mname)
    local cmsg = terralib.new(T.ctype)
    cmsg:init()
    msgs[mname] = {cmsg = cmsg, msg = T, ctype = T.ctype, dump = T.dump}
  end

  local function make_default(kind, repeated)
    if repeated then 
      return {}
    elseif kind == 'double' or kind == 'float' or kind:find('32') or kind == 'enum' then
      return 0
    elseif kind == 'int64' or kind == 'sint64' or kind == 'sfixed64' then
      return 0LL
    elseif kind == 'uint64' or kind == 'fixed64' then
      return 0ULL
    elseif kind == 'string' or kind == 'bytes' then
      return ""
    elseif kind == 'bool' then
      return false
    else
      return {}
    end
  end

  local function prep_test_case(testcase, schemaname)
    local kinds = {}
    local repeated = {}
    local schema = pg.messages[schemaname].schema
    for _, v in ipairs(schema.fields) do
      kinds[v.name] = v.kind
      repeated[v.name] = not not v.repeated
      if testcase[v.name] == nil then
        -- insert default
        testcase[v.name] = make_default(v.kind, v.repeated)
      end
    end
    for fname, fval in pairs(testcase) do
      local kind = kinds[fname]
      local prepper
      if pg.messages[kind] then
        prepper = function(v) return prep_test_case(v, kind) end
      elseif kind == "bytes" then
        prepper = hex_to_bytes
      elseif kind:find("32") then
        -- Hack because Mike generates test cases that turn everything
        -- including 32 bit ints into LLs/ULLs
        prepper = tonumber
      end
      if prepper then
        if repeated[fname] then
          for idx, v in ipairs(testcase[fname]) do
            testcase[fname][idx] = prepper(v)
          end
        else
          testcase[fname] = prepper(fval)
        end
      end
    end
    return testcase
  end

  local test_cases = require("./testgen/test_cases.t")
  for idx, sample in ipairs(test_cases) do
    local mname = sample.message
    if msgs[mname] then
      prep_test_case(sample.truth, mname)
      local cmsg = msgs[mname].cmsg
      cmsg:clear()
      set_fields(cmsg, sample.truth)
      buff:clear()
      local nbytes = msgs[mname].msg.encoder(buff.enc, cmsg)
      buff.enc:compress(buff.buff)
      assert_buff_eq(buff.buff, sample.serial, ("Encode %s case %d"):format(mname, idx))
      
      cmsg:clear()
      buff:clear()
      from_hex(buff.buff, sample.serial)
      local decoded_ok = msgs[mname].msg.decoder(buff.buff, cmsg)
      t.ok(decoded_ok, ("Decode %s case %d"):format(mname, idx))
      --assert_struct_equal(cmsg, sample.truth, ("Decode %s case %d (value)"):format(mname, idx))
      t.expect(msgs[mname].dump(cmsg), sample.truth, ("Decode %s case %d (value)"):format(mname, idx))
    end
  end
end

local function round_trip(buff, Msg, msg_in, msg_out)
  buff:clear()
  local nbytes = Msg.encoder(buff.enc, msg_in)
  buff.enc:compress(buff.buff)
  buff.buff.len = buff.buff.pos
  buff.buff.pos = 0
  msg_out:clear()
  return Msg.decoder(buff.buff, msg_out)
end

local function test_enums(t)
  local schemas = [[
  syntax = "proto3";
  enum Eh {
    EH_ZERO = 0;
    EH_TWELVE = 12;
  }
  enum Bleh {
    BLEH_ZERO = 0;
    BLEH_BANANA = 1000;
  }
  message TwoEnums {
    Eh a = 1;
    Bleh b = 2;
  }
  ]]

  local pg = gen.ProtoGen()
  pg:add_schemas(schemas)

  local two_enums_msg = pg:get("TwoEnums")
  local TwoEnums = two_enums_msg.ctype
  print(TwoEnums:layoutstring())

  local msg = terralib.new(TwoEnums)
  local msg_out = terralib.new(TwoEnums)
  msg.a = pg.enum.EH_TWELVE
  msg.b = pg.enum.BLEH_BANANA

  local buff = allocate_buff()

  t.ok(round_trip(buff, two_enums_msg, msg, msg_out), "TwoEnums decoded OK")
  t.expect(two_enums_msg.dump(msg), two_enums_msg.dump(msg_out), "Round trip OK")
  t.expect(msg_out.a, pg.enum.EH_TWELVE, "Enum a OK")
  t.expect(msg_out.b, pg.enum.BLEH_BANANA, "Enum b OK")
end

local function test_oneof(t)
  local schemas = [[
  syntax = "proto3";
  message Point {
    float x = 1;
    float y = 2;
  }
  message Box {
    float w = 1;
    float h = 2;
    float d = 3;
  }
  message BoxOrPoint {
    oneof content {
      Point point = 1;
      Box box = 2;
    }
  }
  message ListOfThings {
    repeated BoxOrPoint things = 1;
  }
  ]]

  local pg = gen.ProtoGen()
  pg:add_schemas(schemas)

  local BoxOrPoint = pg:get("BoxOrPoint")
  print(BoxOrPoint.ctype:layoutstring())

  local box_msg = terralib.new(BoxOrPoint.ctype)
  box_msg:init()
  local box = box_msg.box:get_or_allocate()
  box.w = 12.0
  box.h = 13.0
  box.d = 14.0
  t.expect(box_msg.point:is_filled(), false, "box has no .point")
  t.expect(box_msg.box:is_filled(), true, "box has .box")

  local point_msg = terralib.new(BoxOrPoint.ctype)
  point_msg:init()
  local point = point_msg.point:get_or_allocate()
  point.x = 1000.0
  point.y = 2000.0
  t.expect(point_msg.point:is_filled(), true, "point has .point")
  t.expect(point_msg.box:is_filled(), false, "point has no .box")

  local msg_out = terralib.new(BoxOrPoint.ctype)
  msg_out:init()
  msg_out.point:allocate()
  msg_out.box:allocate()
  msg_out:clear()
  t.expect(msg_out.box:is_filled(), false, "cleared message has no .box")
  t.expect(msg_out.point:is_filled(), false, "cleared message has no .point")

  local buff = allocate_buff()
  t.ok(round_trip(buff, BoxOrPoint, box_msg, msg_out), "box_msg decoded OK")
  t.expect(msg_out.box:is_filled(), true, "box message has .box")
  do
    local boxref = msg_out.box:get()
    t.expect(boxref.w, 12.0, "box.w is correct")
    t.expect(boxref.h, 13.0, "box.h is correct")
    t.expect(boxref.d, 14.0, "box.d is correct")
  end
  t.expect(msg_out.point:is_filled(), false, "box message does not have .point")
  t.expect(BoxOrPoint.dump(box_msg), BoxOrPoint.dump(msg_out), "Round trip box_msg")

  t.ok(round_trip(buff, BoxOrPoint, point_msg, msg_out), "point_msg decoded OK")
  t.expect(msg_out.box:is_filled(), false, "point message does not have .box")
  t.expect(msg_out.point:is_filled(), true, "point message does have .point")
  t.expect(BoxOrPoint.dump(point_msg), BoxOrPoint.dump(msg_out), "Round trip point_msg")
end

local function test_basic_encoding(t)
  local schemas = {
    Point = {
      name = "Point",
      fields = {
        {name = "x", idx = 1, kind = "int32"},
        {name = "y", idx = 2, kind = "int32"},
        {name = "z", idx = 3, kind = "int32"},
      }
    },
    Line = {
      name = "Line",
      fields = {
        {name = "p0", idx = 1, kind = "Point"},
        {name = "p1", idx = 2, kind = "Point"},
      }
    }
  }

  local pg = gen.ProtoGen()
  pg:add_schemas(schemas)

  local point_message = pg:get("Point")
  local Point = point_message.ctype
  print(Point:layoutstring())

  local line_message = pg:get("Line")
  local Line = line_message.ctype
  print(Line:layoutstring())
  
  local msg = terralib.new(Line)
  local msg_out = terralib.new(Line)
  msg.p0.x = 12
  msg.p0.y = 13
  msg.p0.z = 14
  msg.p1.x = 15
  msg.p1.y = 16
  msg.p1.z = 17

  local buff = allocate_buff()
  buff:clear()
  local line_encoder = line_message.encoder
  local nbytes = line_encoder(buff.enc, msg)
  buff.enc:compress(buff.buff)
  print(nbytes, buff.buff.pos)
  print(as_hex(buff.buff))

  -- HACK: can we avoid this somehow?
  buff.buff.len = buff.buff.pos
  buff.buff.pos = 0
  local decoded_ok = line_message.decoder(buff.buff, msg_out)
  t.ok(decoded_ok, "Line message decoded OK")
  t.expect(line_message.dump(msg), line_message.dump(msg_out), "Round trip submessage")
end

local function test_big_field_indices(t)
  local schemas = {
    Silly = {
      name = "Silly",
      fields = {
        {name = "x", idx = 2^29-1, kind = "int32"}
      }
    }
  }

  local pg = gen.ProtoGen()
  pg:add_schemas(schemas)

  local Silly = pg:get("Silly")
  Silly.decoder:compile()
  print(Silly.decoder:prettystring())
  print(Silly.decoder:disas())
end

function m.run(test)
  test("parser", test_parser)
  test("fundamentals", test_fundamentals)
  test("basic encoding", test_basic_encoding)
  test("primitives", test_primitives)
  test("test_enums", test_enums)
  test("test_oneof", test_oneof)
  --test("silly big indices", test_big_field_indices)
end

return m