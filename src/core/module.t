-- core/module.t
--
-- contains a bunch of useful functions for creating modules

local m = {}

-- copy all public exports from module srcname into destination table
-- if the returned module object has an explicit .exports, use that
-- anything prefixed with _ isn't exported
function m.reexport(srcmodule, desttable)
  desttable = desttable or {}
  local src = rawget(srcmodule, "exports") or srcmodule
  for k,v in pairs(src) do
    if k:sub(1,1) ~= "_" then
      if desttable[k] then
        truss.error("module reexport: destination already has " .. k)
      end
      desttable[k] = v
    else
      log.debug("Skipping " .. k)
    end
  end
  return desttable
end

-- copy all public exports from a list of modules into a destination table
-- ex: include_submodules({"foo/bar.t", "foo/baz.t"}, foo)
function m.include_submodules(srclist, dest)
  dest = dest or {}
  for _, srcname in ipairs(srclist) do
    m.reexport(require(srcname), dest)
  end
  return dest
end

-- (hmmmm)

-- copy values in srctable with prefix into desttable without prefix
-- useful when including a C api that has library_ prefix names on everything
function m.reexport_without_prefix(srctable, prefix, desttable)
  desttable = desttable or {}
  for k,v in pairs(srctable) do
    -- only copy entries that have prefix
    if k:sub(1, prefix:len()) == prefix then
      local renamed = k:sub(prefix:len() + 1)
      if desttable[renamed] then
        truss.error("module rexport: destination already has " .. renamed)
      end
      desttable[renamed] = v
    end
  end
  return desttable
end

local function length_sorted_keys(t)
  local ret = {}
  for k, _ in pairs(t) do
    table.insert(ret, k)
  end
  table.sort(ret, function(x, y) return #x > #y end)
  return ret
end

function m.reexport_renamed(srctable, prefixes, export_unmatched, desttable)
  desttable = desttable or {}
  for k,v in pairs(srctable) do
    local found_prefix = false
    for _, prefix in ipairs(length_sorted_keys(prefixes)) do
      local replacement = prefixes[prefix]
      if k:sub(1, prefix:len()) == prefix then
        local newname = replacement .. k:sub(prefix:len() + 1)
        desttable[newname] = v
        found_prefix = true
        break
      end
    end
    if export_unmatched and (not found_prefix) then
      if desttable[k] then
        truss.error("module rexport: destination already has " .. renamed)
      end
      desttable[k] = v
    end
  end
  return desttable
end

-- create a table that will for the specified keys lazily load the value
function m.create_lazy_loader(loadertable, target)
  local ret = target or {}
  local rmeta = {
    __index = function(t, k)
      if not loadertable[k] then return nil end
      t[k] = loadertable[k](k)
      return t[k]
    end
  }
  setmetatable(ret, rmeta)
  return ret
end

return m
