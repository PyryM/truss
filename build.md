# Truss Build Instructions

Truss builds itself through Terra, so regardless of platform
you will need to obtain either a [prebuilt Terra release](https://github.com/terralang/terra/releases/tag/release-1.0.6)
or compile it yourself from source. The recommended Terra version is 1.0.6, but higher
versions may work.

Place the Terra libraries (`terra.dll|.so|.lib|.a`) into `lib/`, the Terra include
files into `include/terra/` and the Terra executable (`terra|terra.exe`) into the root folder.

## Dependency: trussfs

Truss depends on [trussfs](https://github.com/PyryM/trussfs). This needs to be built through
Rust in the standard way:

```
mkdir _deps
cd _deps
git clone https://github.com/PyryM/trussfs
cd trussfs
cargo build --release
```

Then copy `_deps/trussfs/target/release/*.dll|.lib|.so|.a` into `libs/`.

## truss.exe self-build on Windows
```
terra.exe src\build\selfbuild.t
```

## truss self-build on Linux / OSX / Posix
```
./terra src/build/selfbuild.t
```


## Obtaining additional prebuilt libraries

Windows:
```
truss.exe dev/downloadlibs.t
```

Posix:
```
./truss dev/downloadlibs.t
```

## Building shaders:

Windows:
```
truss.exe dev/buildshaders.t
```

Posix:
```
./truss dev/buildshaders.t
```