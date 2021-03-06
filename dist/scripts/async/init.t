-- async/init.t
--
-- async module definition

local moduleutils = require("core/module.t")
local async = {}

moduleutils.include_submodules({
  "async/promise.t",
  "async/async.t",
  "async/scheduler.t",
  "async/eventqueue.t"
}, async)

return async