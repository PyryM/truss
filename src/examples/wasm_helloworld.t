local WASM_HEADER = [[
int printf (const char *, ... );
]]

local OUTFN = "helloworld.bc"

function init()
  local triple = "wasm32-wasi"
  local cross_target = terralib.newtarget{Triple = triple}

  local io = terralib.includecstring(WASM_HEADER, nil, cross_target)
  local terra helloworld()
    io.printf("Hello World!\n")
  end

  terralib.saveobj(OUTFN, {helloworld=helloworld}, nil, cross_target)
  print("Exported llvm wasm bitcode ->", OUTFN)
end