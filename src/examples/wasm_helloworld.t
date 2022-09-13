local build = require("build/build.t")

local OUTFN = "helloworld.bc"

local function _build()
  local build = require("build/build.t")
  log.info("Build target:", build.target_name())
  local io = build.includecstring[[
  int printf (const char *, ... );
  ]]
  local terra helloworld()
    io.printf("Hello World!\n")
  end
  return helloworld
end

local function init()
  local root = build.create_cross_compilation_root{
    name = "wasm",
    triple = "wasm32-wasi",
  }

  local happy, helloworld = root.pcall(_build)
  assert(happy, "build error?")

  terralib.saveobj(OUTFN, {helloworld=helloworld}, nil, assert(root.cross_target))
  log.crit("Exported llvm wasm bitcode ->", OUTFN)
end

return {init = init}