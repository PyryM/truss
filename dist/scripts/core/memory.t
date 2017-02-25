-- core/memory.t
--
-- memory management functions

local m = {}

-- TODO: implement a malloc option here
function m.allocate(terratype)
  return terralib.new(terratype)
end

function m.allocate_unmanaged(terratype)
  truss.error("Unimplemented")
end

function m.release_unmanaged(mem)
  truss.error("Unimplemented")
end

return m