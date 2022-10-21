local build = require("build/build.t")

local function _build()
  local build = require("build/build.t")
  log.info("Build target:", build.target_name())

  local struct RGBA {
    r: float
    g: float
    b: float
    a: float
  }

  local terra testfunc(v: RGBA): float
    return v.b
  end
  return testfunc
end

local function init()
  local root = build.create_cross_compilation_root{
    name = "wasm",
    triple = "wasm32",
  }

  local happy, testfunc = root.pcall(_build)
  assert(happy, "build error?")

  local OUTFN = "wasm_struct_args.ll"
  terralib.saveobj(OUTFN, {testfunc=testfunc}, nil, assert(root.cross_target))
  log.crit("Exported llvm wasm bitcode/assembly ->", OUTFN)
end

return {init = init}