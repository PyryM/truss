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

### Compiling DirectX11 (dx11) shaders
```
shaderc -f source_fs_file.sc -o output_fs_file.bin --type f -i common\ --platform windows -p ps_4_0 -O 3
```
For vertex shader change `ps_4_0` to `vs_4_0`
(for DirectX9 (dx9) use `ps_3_0` and `vs_3_0`)

### Compiling OpenGL shaders
```
shaderc -f source_fs_file.sc -o output_fs_file.bin --type f -i common\ --platform linux -p 120
```
