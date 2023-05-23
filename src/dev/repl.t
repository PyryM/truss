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

local function main(env)
  env = env or setmetatable({}, {
    __index = function(t, k)
      return rawget(_G, k)
    end
  })
  while true do
    eval(truss.fs.readline(">> "), env)
  end
end

return {main = main}