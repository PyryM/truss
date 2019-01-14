---
title: Introduction
---

Truss is a lightweight framework and flexible set of libraries
for creating interactive 3d/VR desktop experiences such as games,
visualizations, and tools.

What it looks like:

```lua
local App = require("vr/vrapp.t").VRApp
local geometry = require("geometry")
local graphics = require("graphics")
local pbr = require("shaders/pbr.t")

function init()
  app = App{title = "VR Icosphere", create_controllers = true}
  local geo = geometry.icosphere_geo{radius = 0.5, detail = 2}
  local mat = pbr.FacetedPBRMaterial{diffuse = {0.9, 0.6, 0.6},
                                     tint = {0.001, 0.001, 0.001},
                                     roughness = 0.8}
  mesh = app.scene:create_child(graphics.Mesh, "todd mcicosphere", geo, mat)
  mesh.position:set(0, 0.5, 0) -- in VR floor is at y=0 height
end

function update()
  mesh.quaternion:euler{x = 0, y = app.time, z = 0}
  mesh:update_matrix()
  app:update()
end
```

## Installation

Truss can be installed in a few different ways. You can **download a pre-built
application package** or **build it from source**.

### Pre-built application packages

Truss is designed to require minimal host dependencies once built. It does this
by being organized into a `truss[.exe]` executable which can load everything
else it needs from an application package. By default, it looks for this package
in a neighboring `truss.zip` or its local directory, with loose files taking
precedence over those in the archive.

#### A zipped Truss application package

```
.
├── truss.exe
└── truss.zip
```

#### A local-directory Truss application package

```
.
├── truss.exe
├── font
├── include
├── lib
├── models
├── scripts
├── shaders
└── textures
```

{{ site.begin_sidebar }}
<img class="ui centered large image" src="images/logo.png" />
{{ site.end_sidebar }}

This means that using a pre-built Truss package is as simple as downloading the
package, and putting the `truss[.exe]` alongside its application resources. Then
simply run the executable and you should be good to go!

### Installation from source

If you are actively developing truss or do not have a pre-built package
available, Truss can also be built using CMake. Detailed instructions can be
[found on GitHub](https://github.com/PyryM/truss/blob/master/build.md), but the
simple version of it is shown on the right.

#### Building the source using CMake

```
# Install platform dependencies
git clone https://github.com/PyryM/truss.git truss
cd truss
mkdir build
cd build
cmake ..
make
```
