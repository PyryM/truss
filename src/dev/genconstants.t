-- genconstants.t
--
-- use some metaprogramming trickery to extract #define constants
-- for bgfx

local m = {}
local clib = require("substrate/clib.t")
local ffi = require("ffi")

local function make_c_func(funcname, defname)
  local ret = ""
  ret = ret .. "uint64_t " .. funcname .. "() {\n"
  ret = ret .. "    return " .. defname .. ";\n"
  ret = ret .. "}\n"
  return ret
end

local function make_c_file(defpairs)
  local ret =  '#include <stdint.h>\n'
  ret = ret .. '#include "bgfx/defines.h"\n\n'
  for defname, funcname in pairs(defpairs) do
    ret = ret .. make_c_func(funcname, defname)
  end
  return ret
end

local tempbuffer = terralib.new(uint8[255])

local function format_ull_constant(val)
  clib.io.sprintf(tempbuffer, "0x%llxULL", val)
  return ffi.string(tempbuffer)
end

function m.get_constant_values(defnames)
  local defpairs = {}
  for idx, dname in ipairs(defnames) do
    defpairs[dname] = "get_bgfxconst_" .. idx
  end

  local cfile = make_c_file(defpairs)
  log.debug(cfile)

  local compiled = terralib.includecstring(cfile)

  local ret = {}
  for defname, funcname in pairs(defpairs) do
    local val = compiled[funcname]()
    ret[defname] = val
  end

  return ret
end

function m.gen_constants_file(defnames)
  local ullvals = m.get_constant_values(defnames)
  local ret = "--Autogenerated bgfx constants\nreturn {\n"
  local consts = {}
  for idx, defname in ipairs(defnames) do
    local defval = ullvals[defname]
    consts[idx] = ("  %s = %s"):format(defname, format_ull_constant(defval))
  end
  ret = ret .. table.concat(consts, ",\n")
  ret = ret .. "\n}\n"
  return ret
end

return m