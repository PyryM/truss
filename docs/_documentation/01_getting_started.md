---
title: Getting Started

language_tabs: # must be one of https://git.io/vQNgJ
  - lua

toc_footers:
  - <a href='https://github.com/PyryM/truss'>Truss GitHub</a>
  - <a href='https://github.com/lord/slate'>Documentation Powered by Slate</a>

includes:
  - errors

search: true
---

Truss is essentially an extensive set of `lua` bindings for the pieces that you
would need to create a game or visualization engine. Beyond that, it generally
makes very few assumptions about what you are trying to do.

**Let's look at some sample code that renders and displays a sphere.**

{{ site.begin_sidebar }}
#### A simple example program that displays a sphere

```lua
local AppScaffold = require("utils/appscaffold.t").AppScaffold
local icosphere = require("geometry/icosphere.t")
local pbr = require("shaders/pbr.t")
local gfx = require("gfx")

function init()
  app = AppScaffold({title = "minimal_example",
                     width = 1280, height = 720})
  local geo = icosphere.icosphere_geo(1.0, 2, "icosphere")
  local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)
  local sphere = gfx.Object3D(geo, mat)
  app.scene:add(sphere)
end

function update()
  app:update()
end
```
{{ site.end_sidebar }}
