## Package thoughts

* preload 'core': e.g., log, fs, etc. that don't
  depend on rest of truss

* truss root constructor takes in 'core'

* actually, just make a whole *truss root* a thing you can fork!

* Merge 'require root' and 'package root' into a single thing
* (e.g., in cross compilation, we need a whole new package tree!)
* Clone a root: copy *loaders only* and not loaded packages

a package/truss root has:
.require(...) (callable with both . and :?)
.read_file(...)
.list_dir(...)
.fork(...) (produce a fork with no loaded packages, e.g. for cross-compilation)

.loaded (loaded packages)
.preload (not yet loaded packages)


* Flat list of packages
* Mount directory -> add packages
* e.g., add_packages_directory(joinpath(workdir, "src"))
  * add each direct subdir as a package
* add_package(source, name?)
  * source can be either a string path, or an "fs like" object, or a raw package object
    * how to distinguish?
  * name will be inferred from source if not given
* package merging?
  * assets could just all reside in an `assets` package
  * what happens if try to merge packages with `package.t`s? Does one `package.t` 'win'? Or exec *all* `package.t`s?
* file writing: maybe just always happen in real paths
  * built shaders? hmmm
* move src -> packages
* move textures, font, shaders -> assets/textures, assets/font, etc.
* perhaps a package can be mounted as "non executable" which will prevent requiring out of it
  * i.e., only direct read_files are allowed
* truss.read_file vs. truss.read_package_file
  * or just have special paths like "pkg:assets/textures/bla.png"
  * also perhaps "archive:foo.zip:textures/eh.png"
* workdir implicitly in package `WORKDIR` (likewise `TRUSS`?)
  * maybe `HERE`? ("pkg:HERE/whatever") (does this serve any purpose?) (yes, for `require`!)
    * e.g., any script might want to do like `require("WORKDIR/config.t")`
  * then can do like truss.read_file("pkg:TRUSS/include/bgfx/bgfx_truss.c99.h")
* `truss tools/list_packages.t`
* `truss ./inworkdir.t`: should this work somehow?