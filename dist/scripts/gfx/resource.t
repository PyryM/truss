-- gfx/resource.t
--
-- resource management

local class = require("class")
local m = {}

local ResourceContext = class("ResourceContext")
m.ResourceContext = ResourceContext

m._live_handles = {}
m._weak_handles = {}

function m.free_handles()
  for handle, destructor in pairs(m._live_handles) do
    if not m._weak_handles[handle] then
      destructor(handle)
      m._live_handles[handle] = nil
    end
  end
end

return m
