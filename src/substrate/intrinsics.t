local m = {}

local libc = require("./libc.t")
local size_t = libc.std.size_t

-- "i" means "integer" not "signed"
-- (unsure about whether this is safe)
local LLVM_TYPE_SUFFIX = {
  [float] = "f32",
  [double] = "f64",
  [int8] = "i8",
  [uint8] = "i8",
  [int32] = "i32",
  [uint32] = "i32",
  [int64] = "i64",
  [uint64] = "i64",
}

local function llvm_suffix(t)
  if type(t) ~= "string" then 
    if t:ispointer() then
      t = t.type
    end
    t = assert(LLVM_TYPE_SUFFIX[t], "no LLVM suffix for " .. tostring(t)) 
  end
  return t
end

local function intrinsic_name(basename, t)
  return "llvm." .. basename .. "." .. llvm_suffix(t)
end

local function ex_intrinsic_name(basename, argnames, argtypes)
  local argfrags = {}
  for idx = 1, #argtypes do
    argfrags[idx] = (argnames[idx] or "") .. llvm_suffix(argtypes[idx])
  end
  return "llvm." .. basename .. "." .. table.concat(argfrags, ".")
end

local function assert_same_type(fname, a, b)
  local t0 = a:gettype()
  local t1 = b:gettype()
  if not t0 == t1 then
    error("intrinsic " .. fname .. " requires args to have same type: "
          .. tostring(t0) .. " vs. " .. tostring(t1))
  end
end

m.memcpy = macro(function(dest, src, nbytes)
  assert_same_type("memcpy", dest, src)
  local t = dest:gettype()
  local iname = ex_intrinsic_name("memcpy", {"p0", "p0"}, {t, t, size_t})
  local imemcpy = terralib.intrinsic(iname, {t, t, size_t, bool} -> {})
  return `imemcpy(dest, src, nbytes, false)
end)

m.memmove = macro(function(dest, src, nbytes)
  assert_same_type("memmove", dest, src)
  local t = dest:gettype()
  local iname = ex_intrinsic_name("memmove", {"p0", "p0"}, {t, t, size_t})
  local imemmove = terralib.intrinsic(iname, {t, t, size_t, bool} -> {})
  return `imemmove(dest, src, nbytes, false)
end)

m.memset = macro(function(dest, value, nbytes)
  -- TODO: figure out why intrinsic memset gets angry!
  return `libc.string.memset(dest, value, nbytes)
  --[[
  local t = dest:gettype()
  local iname = ex_intrinsic_name("memset", {"p0"}, {t, size_t})
  local imemset = terralib.intrinsic(iname, {t, uint8, size_t, bool} -> {})
  return `imemset(dest, value, nbytes, false)
  ]]
end)

m.min = macro(function(x, y)
  local t = x:gettype()
  if LLVM_TYPE_SUFFIX[t] then
    return `[terralib.intrinsic(intrinsic_name("minnum", t), {t, t} -> t)](x, y)
  else
    return `terralib.select(x < y, x, y)
  end
end)

m.max = macro(function(x, y)
  local t = x:gettype()
  if LLVM_TYPE_SUFFIX[t] then
    return `[terralib.intrinsic(intrinsic_name("maxnum", t), {t, t} -> t)](x, y)
  else
    return `terralib.select(x > y, x, y)
  end
end)

m.abs = macro(function(x)
  local t = x:gettype()
  if LLVM_TYPE_SUFFIX[t] then
    return `[terralib.intrinsic(intrinsic_name("fabs", t), t -> t)](x)
  else
    return `terralib.select(x < 0, -x, x) 
  end
end)

for _, name in pairs{"sqrt", "sin", "cos", "log", "log2", "log10", "exp", "exp2", "exp10", "fabs", "ceil", "floor", "trunc", "rint", "nearbyint", "round"} do
  m[name] = macro(function(x)
    local t = x:gettype()
    return `[terralib.intrinsic(intrinsic_name(name, t), t -> t)](x)
  end)
end

m.pow = macro(function(x, y)
  local pow_name = "llvm.pow"
  local src_t = x:gettype()
  local pow_t = y:gettype()
  if pow_t == int or pow_t == int32 then pow_name = pow_name .. "i" end
  pow_name = pow_name .. "." .. assert(LLVM_TYPE_SUFFIX[src_t], "Pow requires float type!")
  local pfunc = terralib.intrinsic(pow_name, {src_t, pow_t} -> src_t)
  return `pfunc(x, y)
end)

return m