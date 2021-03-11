# Truss Build Instructions

## Windows
* Dependencies:
  * Download and install [`cmake`](https://cmake.org/download/)
  * Download and install [`Visual Studio 2017`](https://www.visualstudio.com/en-us/downloads/download-visual-studio-vs.aspx)

* Compilation
  * Run `cmake-gui`
    * Specify the source directory as your git checkout
    * Specify the build directory as your git checkout + `./build`
    * Click `Configure` and select the compiler `Visual Studio 15 2017 Win64` (make sure to choose 64-bit).
    * Click `Generate`
  * Open the `./build` directory and double-click `truss.sln`
  * In Visual Studio, build the `ALL_BUILD` project to build everything.

## Linux
* Dependencies: `cmake`, `build-essential`, `libxext-dev`, `mesa-common-dev`, `flex` (for shaders), `bison` (for shaders)
  * Get CMake version 3.3+

    **For Ubuntu 16.04+:**

    ```bash
    sudo apt-get install cmake libxext-dev mesa-common-dev flex bison
    ```

    **For Ubuntu <16.04:**

    ```bash
    sudo apt-get install build-essential libxext-dev mesa-common-dev flex bison
    wget http://www.cmake.org/files/v3.3/cmake-3.3.2.tar.gz
    tar xf cmake-3.3.2.tar.gz
    cd cmake-3.3.2/
    ./configure --system-curl
    make
    sudo checkinstall
    ```

    If X11 is not detected by SDL (symptom: error complaining about x11 not being a member of SDLSysWMInfo),
    easiest fix is `sudo apt-get install libsdl2-dev`.

    If at the end a link error with Terra not finding `libtinfo.5.so`, just `sudo apt-get install libtinfo5-dev`.

* Compilation

  ```bash
  mkdir build
  cd build
  cmake ..
  make
  ```

Now you can run:
```bash
./truss scripts/examples/new_basic.t
```
