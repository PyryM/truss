[![Build Status](https://travis-ci.org/PyryM/truss.svg?branch=master)](https://travis-ci.org/PyryM/truss)[![Build status](https://ci.appveyor.com/api/projects/status/805j1wikxyx406ms/branch/master?svg=true)](https://ci.appveyor.com/project/truss/truss/branch/master)

# truss
visualization/rendering framework

## Requirements
Truss is designed for relatively modern computers. In particular,
- 64bit only
- Ubuntu 13.04+ only (unless you want to backport a newer version of gcc)
- Official NVidia drivers (in particular, won't work with linux Mesa Gallium drivers)
- DX11 capable video card recommended on Windows

## [Build instructions](build.md)

## Miscellaneous tips

### Compiling shaders
Copy `shadercRelease[.exe]` (found in e.g., `build\bgfx_EXTERNAL-prefix\src\bgfx_EXTERNAL\.build\win64_vs2015\bin` after building) into `dist/shaders/raw`, and then in that directory run `python compile_shaders.py`.

### Creating a distribution .zip
Truss will try to automatically mount `truss.zip`, so it's possible to create a two-file truss distribution (`truss[.exe]` and `truss.zip`) by zipping up `font`, `include`, `libs`, `scripts`, and `shaders` from `dist/` into `truss.zip`. 
