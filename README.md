[![Build Status](https://travis-ci.org/PyryM/truss.svg?branch=master)](https://travis-ci.org/PyryM/truss)[![Build status](https://ci.appveyor.com/api/projects/status/805j1wikxyx406ms/branch/master?svg=true)](https://ci.appveyor.com/project/truss/truss/branch/master)

# truss
Lua/Terra based visualization/rendering framework, somewhat akin to Processing and Threejs, except with a focus on desktop, VR, and modern rendering features.

## Requirements
Truss is designed for relatively modern computers. In particular,
- 64bit, C++ 11+
- Linux: Any drivers *other* than Mesa
- Windows: only DX11 is actually tested

## [Build instructions](build.md)

## Miscellaneous tips

### Compiling shaders
Run truss at least once so it'll extract `shaderc.exe` into `/bin`.
In `dist/shaders/raw/` run `python compile_shaders.py`.
(Yes it's irritating that you need Python. This will eventually be fixed).

### Creating a distribution .zip
Truss will try to automatically mount `truss.zip`, so it's possible to create a two-file truss distribution (`truss[.exe]` and `truss.zip`) by compressing `dist/` into `truss.zip`. 
