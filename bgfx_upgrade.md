# Upgrading the bgfx version

## Building bgfx
In the bgfx dir,
```
..\bx\tools\bin\windows\genie.exe --with-tools --with-shared-lib vs2015
cd .build\projects\vs2015
start bgfx.sln
```
Change the project configuration to release/x64 and compile. Copy the dll/lib/pdb to trussdeps.

## Updating the headers
Edit the c99/bgfx.h header to be like the previous bgfx_truss.c99.h

## Updating the defines
Run defines_to_list.py on bgfxdefines.h:
```
python defines_to_list.py bgfxdefines.h bgfxdefines.lua
```

Copy the constant names into scripts/devtools/genconstants.t, and edit
bootstrap.t to use the real headers on your system by commenting out
```
terralib.includepath = terralib.includepath .. ";include/fakestd"
```.

Then, run
```
truss devtools/genconstants.t
```

Copy the output from trusslog.txt into bgfx_constants.t