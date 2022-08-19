local function stringify_args(...)
  local nargs = select('#', ...)
  local frags = {}
  for i = 1, nargs do
    frags[i] = tostring(select(i, ...))
  end
  return table.concat(frags, " ")
end

function truss.log(level, ...)
  print("["..level.."]:",...)
end

-- TODO: figure out logging
log = {}
function log.debug(...) truss.log("debug", stringify_args(...)) end
function log.info(...) truss.log("info", stringify_args(...)) end
function log.warn(...) truss.log("warn", stringify_args(...)) end
log.warning = log.warn
function log.error(...) truss.log("error", stringify_args(...)) end
function log.fatal(...) truss.log("fatal", stringify_args(...)) end

-- use default lua error handling
truss.error = error
