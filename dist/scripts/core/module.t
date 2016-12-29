-- core/module.t
--
-- contains a bunch of useful functions for creating modules

local m = {}

-- copy all public exports from module srcname into destination table
-- if the returned module object has an explicit .exports, use that
function m.reexport(srcname, desttable)
  local srcmodule = require(srcname)
  if not srcmodule then
    return
  end
  local src = srcmodule.exports or srcmodule
  for k,v in pairs(src) do
    if not desttable[k] then
      desttable[k] = v
    else
      truss.error("core/module.t: reexport: destination already has " .. k)
    end
  end
end

-- copy all public exports from a list of modules into a destination table
-- ex: include_submodules({"foo/bar.t", "foo/baz.t"}, foo)
function m.include_submodules(srclist, dest)
  for _,srcname in ipairs(srclist) do
    m.reexport(srcname, dest)
  end
end

-- copy values in srctable with prefix into desttable without prefix
-- useful when including a C api that has library_ prefix names on everything
function m.reexport_without_prefix(srctable, prefix, desttable)
  for k,v in pairs(srctable) do
    -- only copy entries that have prefix
    if k:sub(1, prefix:len()) == prefix then
      desttable[k:sub(prefix:len() + 1)] = v 
    end
  end
end

return m
