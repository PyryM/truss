-- devtools/test.t
--
-- largely adapted from 'gambiarra':
-- https://bitbucket.org/zserge/gambiarra
-- (MIT license)

local m = {}

local test_stats = {passed = 0, failed = 0, errors = 0,
                    total_passed = 0, total_failed = 0,
                    verbose = false}

local function TERMINAL_HANDLER(e, test, msg)
  local esc = string.char(27)
  local grn = esc .. "[32m"
  local red = esc .. "[31m"
  local blk = esc .. "[0m"
  if e == 'pass' then
    test_stats.passed = test_stats.passed + 1
    if test_stats.verbose then
      print(grn .. "✔ " .. blk .. test .. ': ' .. msg)
    end
  elseif e == 'fail' then
    test_stats.failed = test_stats.failed + 1
    print(red .. "✘ " .. blk .. test .. ': ' .. msg)
  elseif e == 'except' then
    test_stats.errors = test_stats.errors + 1
    print(red .. "✖✖ " .. blk .. test .. ': ' .. msg)
  elseif e == 'begin' then
  test_stats.passed = 0
  test_stats.failed = 0
  elseif e == 'end' then
    local p, f = test_stats.passed, test_stats.failed
    local color = grn
    if f > 0 then color = red end
    print(color .. "[" .. p .. " / " .. (p+f) .. "] " .. test .. blk)
    test_stats.total_passed = test_stats.total_passed + test_stats.passed
    test_stats.total_failed = test_stats.total_failed + test_stats.failed
  end
end

-- floating point approximate equality
local function approx_eq(a, b, tolerance)
  tolerance = tolerance or 1e-6
  return math.abs(a - b) < tolerance
end

local function deepeq(a, b)
  -- Different types: false
  if type(a) ~= type(b) then 
    print(tostring(a) .. " != " .. tostring(b))
    return false 
  end
  -- Functions
  if type(a) == 'function' then
    return string.dump(a) == string.dump(b)
  end
  -- Primitives and equal pointers
  if a == b then return true end
  -- Only equal tables could have passed previous tests
  if type(a) ~= 'table' then 
    print("????: " .. tostring(a) .. " vs. " .. tostring(b))
    return false 
  end
  -- Compare tables field by field
  for k,v in pairs(a) do
    if b[k] == nil or not deepeq(v, b[k]) then 
      print('keyfail: ' .. k)
      return false 
    end
  end
  for k,v in pairs(b) do
    if a[k] == nil or not deepeq(v, a[k]) then
      print('keyfail: ' .. k) 
      return false 
    end
  end
  return true
end

-- Compatibility for Lua 5.1 and Lua 5.2
local function args(...)
  return {n=select('#', ...), ...}
end

local function spy(f)
  local s = {}
  setmetatable(s, {__call = function(s, ...)
    s.called = s.called or {}
    local a = args(...)
    table.insert(s.called, {...})
    if f then
      local r
      r = args(pcall(f, (unpack or table.unpack)(a, 1, a.n)))
      if not r[1] then
        s.errors = s.errors or {}
        s.errors[#s.called] = r[2]
      else
        return (unpack or table.unpack)(r, 2, r.n)
      end
    end
  end})
  return s
end

local function deepprint(v, seen)
  seen = seen or {}
  if type(v) == 'table' then
    if seen[v] then return "[circular reference]" end
    seen[v] = true
    local frags = {}
    for k, tv in pairs(v) do
      table.insert(frags, tostring(k) .. "= " .. deepprint(tv, seen))
    end
    return "{" .. table.concat(frags, "\n") .. "}"
  else
    return tostring(v)
  end
end

-- a weak-valued table for testing memory management
local handle_table = {}
local next_handle = 1
setmetatable(handle_table, {__mode = "v"})

local function table_exists(self)
  return handle_table[self.handle] ~= nil
end

local function mem_spy(t)
  local handle_idx = next_handle
  next_handle = next_handle + 1
  handle_table[handle_idx] = t
  return {handle = handle_idx, exists = table_exists}
end

local pendingtests = {}
local gambiarrahandler = TERMINAL_HANDLER

function m.set_handler(handler)
  gambiarrahandler = handler
end

local function runpending()
  if pendingtests[1] ~= nil then pendingtests[1](runpending) end
end

function m.test(name, f, async)
  if type(name) == 'function' then
    gambiarrahandler = name
    return
  end

  local testfn = function(next)
    local finish_test = function()
      gambiarrahandler('end', name)
      table.remove(pendingtests, 1)
      if next then next() end
    end

    local handler = gambiarrahandler

    local funcs = {}
    funcs.eq = deepeq
    funcs.approx_eq = approx_eq
    funcs.spy = spy
    funcs.mem_spy = mem_spy
    funcs.ok = function(cond, msg)
      msg = msg or (debug.getinfo(2, 'S').short_src .. ":"
        .. debug.getinfo(2, 'l').currentline)
      if cond then
        handler('pass', name, msg)
      else
        handler('fail', name, msg)
      end
    end
    funcs.expect = function(a, b, msg, err_printer)
      msg = msg or (debug.getinfo(2, 'S').short_src .. ":"
        .. debug.getinfo(2, 'l').currentline)
      if deepeq(a, b) then
        handler('pass', name, msg)
      else
        if err_printer then
          msg = msg .. ": " .. err_printer(a, b)
        else
          msg = msg .. ": expected " .. deepprint(b) .. ", got " .. deepprint(a)
        end
        handler('fail', name, msg)
      end
    end
    funcs.err = function(f2, msg)
      if not msg then
        msg = debug.getinfo(2, 'S').short_src .. ":"
           .. debug.getinfo(2, 'l').currentline
      end
      local ok, err = pcall(f2)
      if not ok then
        handler('pass', name, msg .. ": " .. err)
      else
        handler('fail', name, msg)
      end
    end

    handler('begin', name)
    local ok, err = pcall(f, funcs, finish_test)
    if not ok then handler('except', name, err) end
    if not async then handler('end', name) end
  end

  if not async then
    testfn()
  else
    table.insert(pendingtests, testfn)
    if #pendingtests == 1 then
      runpending()
    end
  end
end

local function make_header(dirpath)
  local npad = 70 - #dirpath
  local t = {}
  for i = 1, npad do t[i] = "=" end
  return "==== " .. dirpath .. " " .. table.concat(t)
end

-- this runs a specific file as tests
local allow_archived = false
local function _run_test_file(dirpath)
  local req_path = table.concat(truss.slice_table(dirpath, 2, -1), "/")
  local rawfn = table.concat(dirpath, "/")
  -- "scripts/" .. dirpath .. "/" .. fn
  if (not allow_archived) and truss.is_archived(rawfn) then
    return
  end
  print(make_header(req_path))
  local tt = require(req_path)
  tt.run()
end

-- run tests on any files names _test*
local function _run_tests(dirpath, force)
  local futils = require("utils/fileutils.t")
  local file_filter = futils.filter_file_prefix("_test")
  for path in futils.iter_walk_files(dirpath, nil, file_filter) do
    _run_test_file(path)
  end
end

function m.run_tests(dirpath, verbose, test_archives)
  allow_archived = not not test_archives -- coerce to bool
  test_stats.total_failed = 0
  test_stats.total_passed = 0
  test_stats.failed = 0
  test_stats.passed = 0
  test_stats.errors = 0
  test_stats.verbose = verbose
  print("verbose? " .. tostring(verbose))
  _run_tests({"scripts", dirpath})
  print(make_header("TOTAL"))
  print("PASSED: " .. test_stats.total_passed)
  print("FAILED: " .. test_stats.total_failed)
  if test_stats.total_failed == 0 and test_stats.errors == 0 then
    local slots = require("devtools/slots.t")
    print("Good job! " .. slots.do_slots(true))
  elseif test_stats.errors > 0 then
    print("Tests had errors!!!!")
  end
end

function m.init()
  if truss.args[3] then
    m.run_tests(truss.args[3], true)
  else -- if no path specified, run all tests, but non-verbose
    m.run_tests(nil, false)
  end
end

function m.update()
  print("Tests completed.")
  truss.quit()
end

return m
