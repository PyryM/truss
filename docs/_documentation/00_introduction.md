---
title: Introduction

language_tabs: # must be one of https://git.io/vQNgJ
  - lua

toc_footers:
  - <a href='https://github.com/PyryM/truss'>Truss GitHub</a>
  - <a href='https://github.com/lord/slate'>Documentation Powered by Slate</a>

includes:
  - errors

search: true
---

Truss is an opinionated game/visualization engine built upon a cross-platform
core of libraries bound together with the powerful **lua**/**terra** language
engines.

> ![Image of Yaktocat](images/logo.png)

# Installation

Truss can be installed in a few different ways. You can **download a pre-built
application package** or **build it from source**.

## Pre-built application packages

Truss is designed to require minimal host dependencies once built. It does this
by being organized into a `truss[.exe]` executable which can load everything
else it needs from an application package. By default, it looks for this package
in a neighboring `truss.zip` or its local directory.

<div class="ui right rail">
  <div class="ui segment">
    <img src="images/logo.png" />
  </div>
</div>

> A zipped Truss application package

```
.
├── truss.exe
└── truss.zip
```

> A local-directory Truss application package

```
├── truss.exe
├── font
├── include
├── lib
├── models
├── scripts
├── shaders
└── textures
```

This means that using a pre-built Truss package is as simple as downloading the
package, and putting the `truss[.exe]` alongside its application resources. Then
simply run the executable and you should be good to go!

## Installation from source

If you are actively developing truss or do not have a pre-built package
available, Truss can also be built using CMake. Detailed instructions can be
[found on GitHub](https://github.com/PyryM/truss/blob/master/build.md), but the
simple version of it is shown on the right.

> Building the source using CMake

```
# Install platform dependencies
git clone https://github.com/PyryM/truss.git truss
cd truss
mkdir build
cd build
cmake ..
make
```
