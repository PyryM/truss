local function stringify_args(...)
  local nargs = select('#', ...)
  local frags = {}
  for i = 1, nargs do
    frags[i] = tostring(select(i, ...))
  end
  return table.concat(frags, " ")
end

function truss.log(level, ...)
  print(level, ...)
end

-- TODO: figure out logging
log = {}
function log.debug(...) truss.log(4, stringify_args(...)) end
function log.info(...) truss.log(3, stringify_args(...)) end
function log.warn(...) truss.log(2, stringify_args(...)) end
log.warning = log.warn
function log.error(...) truss.log(1, stringify_args(...)) end
function log.critical(...) truss.log(0, stringify_args(...)) end

-- use default lua error handling
truss.error = error
