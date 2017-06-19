-- ecs/init.t
--
-- ecs metamodule

local modutils = require("core/module.t")
local ecs = {}

modutils.include_submodules({
  "ecs/entity.t",
  "ecs/component.t",
  "ecs/system.t",
  "ecs/event.t",
  "ecs/ecs.t"
}, ecs)

return ecs
