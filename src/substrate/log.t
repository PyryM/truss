local m = {}

function m.default_log(cfg)
  local libc = require("./libc.t")

  local function default_print(fmt, ...)
    fmt = fmt .. "\n" -- convention is that dbgprint is always on newline
    local args = {...} -- can't do this inline in quote below for reasons
    return quote 
      libc.io.printf(fmt, [args])
    end
  end

  return default_print
end

return m