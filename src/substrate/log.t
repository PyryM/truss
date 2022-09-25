local m = {}

function m.default_log(cfg)
  local clib = require("./clib.t")

  local function default_print(fmt, ...)
    fmt = fmt .. "\n" -- convention is that dbgprint is always on newline
    local args = {...} -- can't do this inline in quote below for reasons
    return quote 
      clib.io.printf(fmt, [args])
    end
  end

  return default_print
end

return m