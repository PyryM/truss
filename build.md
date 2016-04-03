# Truss Build Instructions

> :warning: **IMPORTANT: truss is currently using bgfx commit**
> `f7130318c0cf62f42ae4b8a76633c9e09409f32b`

## Windows (vs2013)
* Dependencies: bgfx, bx, terra, sdl
  * Get and build bgfx + bx (bx is header only and needed by bgfx):
    ```bash
    git clone git://github.com/bkaradzic/bx.git
    git clone git://github.com/bkaradzic/bgfx.git
    cd bgfx
    ..\bx\tools\bin\windows\genie --with-shared-lib --with-tools vs2013
          (might also want --with-ovr)
          (note: what does --with-sdl do? It doesn't seem to be needed...)
    start .build\projects\vs2013\bgfx.sln
          (make sure to build in x64!)
    ```

## Linux
* Dependencies: cmake, sdl
  * Get CMake version 3.3+
    **For Ubuntu 16.04+:**
    ```bash
    sudo apt-get install cmake
    ```
    **For Ubuntu <16.04:**
    ```bash
    sudo apt-get install build-essential
    wget http://www.cmake.org/files/v3.3/cmake-3.3.2.tar.gz
    tar xf cmake-3.3.2.tar.gz
    cd cmake-3.3.2/
    ./configure --system-curl
    make
    sudo checkinstall
    ```

  * Get SDL:
    ```bash
    sudo apt-get install libsdl2-dev
    ```

* Make:
  ```bash
  mkdir build
  cd build
  cmake ..
  make
  ```

Now you can hopefully run:
```bash
./truss scripts/examples/dart_gui_test.t
```

> Note: if you want bgfx to use opengl > 2.1, then you need to compile it with
> e.g. `#define BGFX_CONFIG_RENDERER_OPENGL 31`
> either by manually setting this define (ex: in bgfx/src/config.h) or through
> the build process somehow.
