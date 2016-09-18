# Truss Build Instructions

## Windows
* Dependencies:
  * Download and install [`cmake`](https://cmake.org/download/)
  * Download and install [`Visual Studio 2015`](https://www.visualstudio.com/en-us/downloads/download-visual-studio-vs.aspx)

* Compilation
  * Run `cmake-gui`
    * Specify the source directory as your git checkout
    * Specify the build directory as your git checkout + `./build`
    * Click `Configure` and select the compiler `Visual Studio 14 2015 Win64` (make sure to choose 64-bit).
    * Click `Generate`
  * Open the `./build` directory and double-click `truss.sln`
  * In Visual Studio, build the `ALL_BUILD` project to build everything.

## Linux
* Dependencies: `cmake`, `build-essential`, `libxext-dev`, `mesa-common-dev`
  * Get CMake version 3.3+

    **For Ubuntu 16.04+:**

    ```bash
    sudo apt-get install cmake libxext-dev mesa-common-dev
    ```

    **For Ubuntu <16.04:**

    ```bash
    sudo apt-get install build-essential libxext-dev mesa-common-dev
    wget http://www.cmake.org/files/v3.3/cmake-3.3.2.tar.gz
    tar xf cmake-3.3.2.tar.gz
    cd cmake-3.3.2/
    ./configure --system-curl
    make
    sudo checkinstall
    ```

* Compilation

  ```bash
  mkdir build
  cd build
  cmake ..
  make
  ```

Now you can run:
```bash
./truss examples/00_buffercube.t
```

> Note: if you want `bgfx` to use OpenGL > 2.1, then you need to compile it with
> e.g. `#define BGFX_CONFIG_RENDERER_OPENGL 31`
> either by manually setting this define (ex: in `bgfx/src/config.h`) or through
> the build process somehow.
