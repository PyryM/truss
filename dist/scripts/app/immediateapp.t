-- immediateapp.t
--
-- a convenience class for immediate-mode only rendering

local graphics = require("graphics")
--local immediate = require("graphics/imrender.t")

local app = require("app/app.t")
local m = {}

local ImmediateApp = app.App:extend("ImmediateApp")
m.ImmediateApp = ImmediateApp

local function terminate(msg)
  if msg then print(msg) end
  truss.quit()
end

function ImmediateApp:init(options)
  ImmediateApp.super.init(self, options)
  if options.func then
    self.imstage:run(options.func, terminate, terminate)
  end
end

-- this creates a pipeline with nothing but an immediate state
function ImmediateApp:init_pipeline(options)
  local p = graphics.Pipeline({verbose = true})
  self.imstage = p:add_stage(graphics.ImmediateStage{
    num_views = options.num_views or 32
  })
  self.pipeline = p
  self.ECS.systems.render:set_pipeline(p)
end

return m
