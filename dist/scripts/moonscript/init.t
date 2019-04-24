-- moonscript/init.t
--
-- the moonscript loader

local m = {}

local loader = require("core/loader.t")

local envgen = loader.create_env_gen()
local resolver = loader.create_prefix_resolver("moonscript/", ".lua")
local preload = {lpeg = require("lib/lulpeg.lua")}

local _require = loader.create_lua_require(resolver, loadstring, envgen, preload)

m.moonscript = _require("moonscript.base")

function m.load(reader, chunkname)
  local s = (type(reader) == 'string' and reader) or ""
  while type(reader) == 'function' do
    local s2 = reader()
    if not s2 then break end
    s = s .. s2
  end
  local code, ltable = m.moonscript.to_lua(s)
  if not code then return code, ltable end
  return loadstring(code, chunkname)
end

m.loadstring = m.load

function m.compile(s)
  return m.moonscript.to_lua(s)
end

return m