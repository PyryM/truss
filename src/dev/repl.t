local term = truss.term

local function colored(color, text)
  return term.color(term[color]) .. text .. term.RESET
end

local function strlit(v)
  local has_quote = not not v:find('"')
  local has_apos = not not v:find("'")
  if has_quote and (not has_apos) then
    return "'" .. v .. "'"
  else 
    local escaped = v:gsub('"', '\\"')
    return '"' .. escaped .. '"'
  end
end

local function format_val(v)
  local vt = type(v)
  local prefix = vt .. ": "
  if vt == "string" then
    v = strlit(v)
  elseif vt == "table" or vt == "function" then
    v = tostring(v):gsub(prefix, "")
  else
    v = tostring(v)
  end
  return colored("WHITE", prefix) .. v
end

local function print_result(happy, ...)
  if not happy then
    print(colored('RED', select(1, ...)))
  elseif select('#', ...) > 0 then
    local frags = {}
    for idx = 1, select('#', ...) do
      frags[idx] = format_val(select(idx, ...))
    end
    print(table.concat(frags, ", "))
  end
end

local TAG = "repl"

local function eval(source, env)
  -- first, see if it will compile as an expression
  local func, err = truss.loadstring("return " .. source, "repl")
  if not func then
    func, err = truss.loadstring(source, "repl")
  end
  if not func then 
    log.error(err)
    return NO_RESULT
  end
  if env then setfenv(func, env) end
  print_result(pcall(func))
end

local function repl_loop(env, cond)
  cond = cond or {quit = false}
  while not cond.quit do
    local line, err = truss.fs.readline(">> ")
    if line then
      eval(line, env)
    elseif err == "Interrupted" or err == "EOF" then
      return err
    else
      error(err)
    end
  end
  return cond.quit
end

local function embed(...)
  local cond = {quit = false}
  local env = {}
  function env.done()
    cond.quit = true
  end
  function env.locals(level)
    local list = {}
    for idx = 1, 255 do
      local name, value = debug.getlocal((level or 0) + 6, idx)
      if not name then break end
      list[name] = value
    end
    return list
  end
  setmetatable(env, {
    __index = function(t, k)
      return rawget(_G, k)
    end
  })
  log.crit("EMBED:", ...)
  return repl_loop(env, cond)
end

local function main(env)
  env = env or setmetatable({}, {
    __index = function(t, k)
      return rawget(_G, k)
    end
  })
  log.crit(repl_loop(env))
end

return {main = main, embed = embed}