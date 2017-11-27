---
title: API Reference

language_tabs: # must be one of https://git.io/vQNgJ
  - lua

toc_footers:
  - <a href='https://github.com/PyryM/truss'>Truss GitHub</a>
  - <a href='https://github.com/lord/slate'>Documentation Powered by Slate</a>

includes:
  - errors

search: true
---

# Introduction

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

# Getting Started

Truss is essentially an extensive set of `lua` bindings for the pieces that you
would need to create a game or visualization engine. Beyond that, it generally
makes very few assumptions about what you are trying to do.

**Let's look at some sample code that renders and displays a sphere.**

> A simple example program that displays a sphere

```lua
local AppScaffold = require("utils/appscaffold.t").AppScaffold
local icosphere = require("geometry/icosphere.t")
local pbr = require("shaders/pbr.t")
local gfx = require("gfx")

function init()
  app = AppScaffold({title = "minimal_example",
                     width = 1280, height = 720})
  local geo = icosphere.icosphere_geo(1.0, 2, "icosphere")
  local mat = pbr.PBRMaterial("solid"):roughness(0.8):tint(0.1,0.1,0.1)
  local sphere = gfx.Object3D(geo, mat)
  app.scene:add(sphere)
end

function update()
  app:update()
end
```

# Random boilerplate

Kittn uses API keys to allow access to the API. You can register a new Kittn API
key at our [developer portal](http://example.com/developers).

Kittn expects for the API key to be included in all API requests to the server
in a header that looks like the following:

`Authorization: meowmeowmeow`

<aside class="notice">
You must replace <code>meowmeowmeow</code> with your personal API key.
</aside>

# Kittens

## Get All Kittens

```ruby
require 'kittn'

api = Kittn::APIClient.authorize!('meowmeowmeow')
api.kittens.get
```

```python
import kittn

api = kittn.authorize('meowmeowmeow')
api.kittens.get()
```

```shell
curl "http://example.com/api/kittens"
  -H "Authorization: meowmeowmeow"
```

```javascript
const kittn = require('kittn');

let api = kittn.authorize('meowmeowmeow');
let kittens = api.kittens.get();
```

> The above command returns JSON structured like this:

```json
[
  {
    "id": 1,
    "name": "Fluffums",
    "breed": "calico",
    "fluffiness": 6,
    "cuteness": 7
  },
  {
    "id": 2,
    "name": "Max",
    "breed": "unknown",
    "fluffiness": 5,
    "cuteness": 10
  }
]
```

This endpoint retrieves all kittens.

### HTTP Request

`GET http://example.com/api/kittens`

### Query Parameters

| Parameter    | Default | Description                                                                      |
| ------------ | ------- | -------------------------------------------------------------------------------- |
| include_cats | false   | If set to true, the result will also include cats.                               |
| available    | true    | If set to false, the result will include kittens that have already been adopted. |

<aside class="success">
Remember — a happy kitten is an authenticated kitten!
</aside>

## Get a Specific Kitten

```ruby
require 'kittn'

api = Kittn::APIClient.authorize!('meowmeowmeow')
api.kittens.get(2)
```

```python
import kittn

api = kittn.authorize('meowmeowmeow')
api.kittens.get(2)
```

```shell
curl "http://example.com/api/kittens/2"
  -H "Authorization: meowmeowmeow"
```

```javascript
const kittn = require('kittn');

let api = kittn.authorize('meowmeowmeow');
let max = api.kittens.get(2);
```

> The above command returns JSON structured like this:

```json
{
  "id": 2,
  "name": "Max",
  "breed": "unknown",
  "fluffiness": 5,
  "cuteness": 10
}
```

This endpoint retrieves a specific kitten.

<aside class="warning">Inside HTML code blocks like this one, you can't use Markdown, so use <code>&lt;code&gt;</code> blocks to denote code.</aside>

### HTTP Request

`GET http://example.com/kittens/<ID>`

### URL Parameters

| Parameter | Description                      |
| --------- | -------------------------------- |
| ID        | The ID of the kitten to retrieve |

## Delete a Specific Kitten

```ruby
require 'kittn'

api = Kittn::APIClient.authorize!('meowmeowmeow')
api.kittens.delete(2)
```

```python
import kittn

api = kittn.authorize('meowmeowmeow')
api.kittens.delete(2)
```

```shell
curl "http://example.com/api/kittens/2"
  -X DELETE
  -H "Authorization: meowmeowmeow"
```

```javascript
const kittn = require('kittn');

let api = kittn.authorize('meowmeowmeow');
let max = api.kittens.delete(2);
```

> The above command returns JSON structured like this:

```json
{
  "id": 2,
  "deleted": ":("
}
```

This endpoint deletes a specific kitten.

### HTTP Request

`DELETE http://example.com/kittens/<ID>`

### URL Parameters

| Parameter | Description                    |
| --------- | ------------------------------ |
| ID        | The ID of the kitten to delete |
