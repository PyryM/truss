local m = {}

local LLVM_TYPE_SUFFIX = {
  [float] = "f32",
  [double] = "f64",
  [int8] = "i8",
  [uint8] = "u8",
  [int32] = "i32",
  [uint32] = "u32",
  [int64] = "i64",
  [uint64] = "u64",
}

local function intrinsic_name(basename, t)
  if type(t) ~= "string" then t = LLVM_TYPE_SUFFIX[t] end
  return "llvm." .. basename .. "." .. t
end

m.memcpy = macro(function(dest, src, nbytes)
  local t = x:gettype()
  assert(t == y:gettype(), "intrinsic memcpy requires dest and src to have same type!")
  local imemcpy = terralib.intrinsic(intrinsic_name("llvm.memcpy.p0.p0", t))
  return `imemcpy(dest, src, nbytes, 0)
end)

m.memmove = macro(function(dest, src, nbytes)
  local t = x:gettype()
  assert(t == y:gettype(), "intrinsic memmove requires dest and src to have same type!")
  local imemmove = terralib.intrinsic(intrinsic_name("llvm.memmove.p0.p0", t))
  return `imemmove(dest, src, nbytes, 0)
end)

m.memset = macro(function(dest, value, nbytes)
  local t = x:gettype()
  local imemset = terralib.intrinsic(intrinsic_name("llvm.memset.p0", t))
  return `imemset(dest, value, nbytes, 0)
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