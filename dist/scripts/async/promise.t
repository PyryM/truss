-- async/promise.t
--
-- basically just renames lib/deferred

local deferred = require("lib/deferred.lua")
local m = {}

m.Promise = deferred.new
m.all = deferred.all
m.any = deferred.argfirst
m.first = deferred.first
m.argfirst = deferred.argfirst
m.map = deferred.map

return m