--[[
  ## Minimal Example

  Create a rotating mesh
]]

--[[
  Typical requires.
]]
local App = require("app/app.t").App
local geometry = require("geometry")
local graphics = require("graphics")
local pbr = require("material/pbr.t")

--[[ 
  A script loaded as the 'main' script has to define two functions:
  `init` and `update`.
]]
function init()
  --[[
    App is a class that takes care of setup for common use-cases. We move
    the camera it creates away from the origin so it will be able to see the mesh
    we create.
  ]]
  app = App{width = 1280, height = 720, title = "Minimal Example", msaa = true}
  app.camera.position:set(0, 0, 3)
  app.camera:update_matrix()

  --[[
    Normally to draw things you'll use Mesh entities which require a geometry
    and a material to create. Both geometries and materials can (and should!)
    be shared across multiple Mesh instances.
  ]]
  local geo = geometry.icosphere_geo{detail = 2}
  local mat = pbr.FacetedPBRMaterial{
    diffuse = {0.2, 0.03, 0.01, 1.0}, 
    tint = {0.001, 0.001, 0.001}, 
    roughness = 0.7
  }

  --[[
    Entity contruction is a bit unconventional in that you pass the constructor
    itself to methods like `create_child`: this simplifies the Entity lifecycle
    because entities are always created within an ECS context (in this case,
    inheriting the context of app.scene).
  ]]
  mesh = app.scene:create_child(graphics.Mesh, "mesh", geo, mat)
end

--[[
  App's update does most of the hard work, we just rotate our mesh. Note that
  changing a mesh's position/quaterion/scale does not automatically update its
  transform matrix (which is what the renderer actually cares about).
]]
local t = 0
function update()
  t = t + 1
  mesh.quaternion:euler{x = 0, y = t / 60, z = 0}
  mesh:update_matrix()
  app:update()
end
