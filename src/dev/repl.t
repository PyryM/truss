local function print_result(happy, ...)
  if not happy then
    log.error(res)
  elseif select('#', ...) > 0 then
    print(...)
  end
end

local function eval(source, env)
  -- first, see if it will compile as an expression
  local func, err = truss.loadstring("return " .. source, "stdio")
  if not func then
    func, err = truss.loadstring(source, "stdio")
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
    eval(truss.fs.readline(">>"), env)
  end
end

return {main = main}