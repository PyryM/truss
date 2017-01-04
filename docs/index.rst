.. truss documentation master file, created by
   sphinx-quickstart on Sun Jan  1 16:53:55 2017.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

.. highlight:: lua

Welcome to truss's documentation!
=================================

.. toctree::
  :maxdepth: 2
  :caption: Contents:
  
  gfx/geometry

Truss is an unopinionated, code-first game/visualization engine written
primarily in Lua/terra, wrapped in a thin layer of C++ to simplify deployment
and linking against C/C++ libraries.

Look how easy it is to use::

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

Features
--------

- Be awesome
- Make things faster

Installation
------------

Simplest option: grab precompiled binaries.

Compiling yourself: truss uses cmake. In brief::

  mkdir build
  cd build
  cmake ..
  make

Truss binaries will have been moved into ``dist/``.

Distribution/Deployment
-----------------------

Truss is designed to be simple to distribute. By default, truss will try to
mount ``truss.zip`` into its virtual file system; this means that ``dist/`` can
be compressed into a zip file and distributed alongside ``truss.exe``. You can
include your own assets/scripts either as loose files, or by adding them in
``truss.zip``, or by mounting additional archives into the virtual file system.


Contribute
----------

- Source Code: github.com/PyryM/truss

License
-------

The project is licensed under the MIT license.


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
