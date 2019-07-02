-- vr_annotate.moon
--
-- annotate locations on a model in VR

geometry = require "geometry"
graphics = require "graphics"
gfx = require "gfx"
pbr = require "material/pbr.t"
ecs = require "ecs"
ms = require "moonscript"
async = require "async"
argparse = require "utils/argparse.t"
math = require "math"

openvr = require "vr/openvr.t"
vrcomps = require "vr/components.t"
VRApp = (require "vr/vrapp.t").VRApp
Grid = (require "graphics/grid.t").Grid

-- app is exported rather than local so if we need to debug it'll
-- be available in truss.main_env
export app

dump_relative_poses = (parent, children) ->
  par_mat_inv = (math.Matrix4!)\invert parent.matrix_world
  out_data = for child in *children
    relative = (par_mat_inv * child.matrix_world)\remove_scaling!
    print relative
    relative\to_table! 
  json = require "lib/json.lua"
  truss.save_string "annotations.json", (json\encode_pretty out_data)

-- in moonscript we have to explicitly 'export' init and update
export init = ->
  app = VRApp {
    title: "vr model annotator",
    mirror: "both",
    stats: true,
    create_controllers: true
  }

  grid = app.scene\create_child Grid, "mygrid", {
    thickness: 0.01, color: {0.6, 0.6, 0.6}
  }
  grid.quaternion\euler {x: math.pi / 2.0}
  grid\update_matrix!

  widget_geo = geometry.axis_widget_geo {scale: 0.1}
  make_widget = (color) ->
    mat = pbr.FacetedPBRMaterial{diffuse: color, tint: {0.001, 0.001, 0.001}, roughness: 0.7}
    with app.scene\create_child graphics.Mesh, "widget", widget_geo, mat
      .visible = false
  COLORS = {{1, 0.5, 0.5}, {0.5, 1, 0.5}, {0.5, 0.5, 1}}
  widgets = [make_widget c for c in *COLORS]

  t = async.run ->
    args = argparse.parse!
    modelname = (args['--model'] or 'controller')\lower!

    modelgeo = if modelname == 'controller'
      while #app.controllers == 0 do async.await_frames!
      p = async.Promise!
      app.controllers[1].controller\load_model((task) -> p\resolve task.geo, 
                                                      -> p\reject!, false)
      async.await p
    else
      loader = switch (modelname\sub -4) 
        when '.obj' then require "loaders/objloader.t"
        when '.stl' then require "loaders/stlloader.t"
      (gfx.StaticGeometry!)\from_data (loader.load modelname)

    modelmat = pbr.FacetedPBRMaterial{
      diffuse: {0.2, 0.03, 0.01, 1.0}, tint: {0.001, 0.001, 0.001}, roughness: 0.7
    }
    model_scale = (tonumber args['--scale']) or 1.0
    model = with app.scene\create_child graphics.Mesh, "Model", modelgeo, modelmat
      .position\set 0, (tonumber args['--height']) or 1.0, 0
      .scale\set model_scale, model_scale, model_scale
      \update_matrix!
    
    while #app.controllers == 0 do async.await_frames!
    offset = with make_widget {0.7, 0.7, 0.7}
      \set_parent app.controllers[1]
      .position\set 0, 0, -0.05
      \update_matrix!
      .visible = true
    widget_idx = 1

    app.controllers[1].controller\on "button", app, (_app, evtname, evt) ->
      print evt.name, evt.state, evt.axis
      if evt.state < 2 then return
      switch evt.name 
        when 'SteamVR_Trigger'
          widgets[widget_idx].visible = true
          widgets[widget_idx].matrix\copy offset.matrix_world
        when 'Grip'
          widget_idx = (widget_idx % 3) + 1
        when 'SteamVR_Touchpad'
          pos = evt.trackable.axes[0].value
          if pos.elem.x < -0.5
            model_scale *= 0.9
          elseif pos.elem.x > 0.5
            model_scale *= 1.0/0.9
          model.scale\set model_scale, model_scale, model_scale
          model\update_matrix!
        when 'ApplicationMenu'
          dump_relative_poses model, widgets 
  t\next print, print

export update = ->
  app\update!
