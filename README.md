# truss
visualization/rendering framework

## Requirements
Truss is designed for relatively modern computers. In particular,
- 64bit only
- Ubuntu 13.04+ only (unless you want to backport a newer version of gcc)
- Official NVidia linux drivers (in particular, won't work with Mesa Gallium drivers)
- DX11 capable video card recommended on Windows

## [Build instructions](build.md)

## Miscellaneous tips

### Compiling dx11 shaders
```
shaderc -f source_fs_file.sc -o output_fs_file.bin --type f -i common\ --platform windows -p ps_4_0 -O 3
```
For vertex shader change `ps_4_0` to `vs_4_0`
(for dx9 use `ps_3_0` and `vs_3_0`)

### Compiling opengl shaders
```
shaderc -f source_fs_file.sc -o output_fs_file.bin --type f -i common\ --platform linux -p 120
```
