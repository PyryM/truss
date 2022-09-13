-- building/cross-compilation functions
local m = {}

function m.is_native()
  return (not _modroot) or (_modroot.cross_target == nil)
end

function m.target_name()
  if m.is_native() then
    return truss.os
  else
    return _modroot.cross_target_name or "Unknown"
  end
end

function m.includec(filename, args, target)
  if not m.is_native() then
    assert(target == nil, "cannot cross-compile within a cross-compilation context!")
    args = _modroot.cross_args
    target = _modroot.cross_target
  end
  log.build("including c [native? ", m.is_native(), "]: ", filename)
  return terralib.includec(filename, args, target)
end

function m.includecstring(str, args, target)
  if not m.is_native() then
    assert(target == nil, "cannot cross-compile within a cross-compilation context!")
    args = _modroot.cross_args
    target = _modroot.cross_target
  end
  log.build("including cstr [native? ", m.is_native(), "]: ", str:sub(1, 80))
  return terralib.includecstring(str, args, target)
end

function m.linklibrary(fn)
  if not m.is_native() then return end
  return terralib.linklibrary(fn)
end

function m.truss_link_library(...)
  if not m.is_native() then return end
  return truss.link_library(...)
end

function m.create_cross_compilation_root(options)
  local target = options.target
  local target_name = options.name
  if not target then
    if not options.triple then
      log.fatal("Either .target or .triple is required for a cross-compilation root!")
      error("Invalid options for create_cross_compilation_root")
    end
    target = terralib.newtarget{
      Triple = options.triple,
      Features = options.features 
    }
    target_name = target_name or options.triple
  end

  local root = truss.create_require_root{
    root = {
      cross_args = options.include_args,
      cross_target = target,
      cross_target_name = target_name or "cross",
    },
  }
  return root
end

return m
