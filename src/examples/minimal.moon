-- minimal.moon
--
-- minimal moonscript example

App = require("app/app.t").App
geometry = require("geometry")
graphics = require("graphics")
pbr = require("material/pbr.t")
ecs = require("ecs")
ms = require("moonscript")

-- app is exported rather than local so if we need to debug it'll
-- be available in truss.main_env
export app

class Rotator extends ms.wrap_lua_class(ecs.UpdateComponent)
  new: =>
    @theta = 0.0
  update: =>
    @theta += 0.01
    @ent.quaternion\euler{x: 0, y: @theta, z: 0}
    @ent\update_matrix!

-- in moonscript we have to explicitly 'export' init and update
export init = ->
  app = App {
    width: 1280, 
    height: 720,
    title: "moonscript example",
    msaa: true
  }
  app.camera.position\set 0, 0, 3
  app.camera\update_matrix!

  geo = geometry.icosphere_geo {detail: 2}
  mat = pbr.FacetedPBRMaterial{
    diffuse: {0.2, 0.03, 0.01, 1.0}, 
    tint: {0.001, 0.001, 0.001}, 
    roughness: 0.7
  }

  with app.scene\create_child graphics.Mesh, "mesh", geo, mat
    \add_component Rotator!

export update = ->
  app\update!
