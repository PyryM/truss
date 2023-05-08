-- jape (real name TBD):
-- a kinda roughly jest-equivalent test framework

--[[
TS reference:
import { expect, test } from "bun:test";

test("2 + 2", () => {
  expect(2 + 2).toBe(4);
});

describe("arithmetic", () => {
  test("2 + 2", () => {
    expect(2 + 2).toBe(4);
  });

  test("2 * 2", () => {
    expect(2 * 2).toBe(4);
  });
});
]]

local sutil = require("util/string.t")
local term = truss.term

local COLORS = {
  OK = term.boldcolor(term.GREEN),
  FAIL = term.boldcolor(term.RED),
  SKIP = term.color(term.CYAN)
}
local BADGES = {
  OK = "✓ ok",
  FAIL = "✗ fail",
  SKIP = "(skip)"
}

local function fmt_cond(cond, text)
  return table.concat{
    COLORS[cond], BADGES[cond], term.RESET,
    ": ", text
  }
end

local function NYI()
  assert(false, "NYI!")
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

local function deepeq(a, b)
  if a == b then return true end
  local atype = type(a)
  if atype ~= type(b) then 
    return false 
  end
  if atype == 'function' then
    return string.dump(a) == string.dump(b)
  elseif atype == 'table' then
    for k, v in pairs(a) do
      if b[k] == nil or not deepeq(v, b[k]) then 
        return false 
      end
    end
    for k, v in pairs(b) do
      if a[k] == nil or not deepeq(v, a[k]) then
        return false 
      end
    end
    return true
  else
    return false 
  end
end

local function contains(a, b)
  NYI()
end

local function try_get(t, k)
  local happy, v = pcall(function()
    return t[k]
  end)
  return happy and v
end

local function _get_prop(t, path, path_idx)
  local k = path[path_idx]
  tk = try_get(t, k)
  if path_idx < #path then
    if not tk then return nil end
    return _get_prop(tk, path, path_idx+1)
  else
    return tk
  end
end

local function get_prop(t, path, v)
  if type(path) == 'string' then
    path = require("util/string.t").split("%.", path)
  end
  return _get_prop(t, path, 1)
end

local jape = {}
jape.scopes = truss.Stack()

local function for_each_scope(f)
  for idx = 1, jape.scopes:size() do
    f(jape.scopes[idx])
  end
end

local function invoke_callbacks(name, reverse, ...)
  for idx = 1, jape.scopes:size() do
    local scope = (reverse and jape.scopes[-idx]) or jape.scopes[idx]
    for _, cb in ipairs(scope.callbacks[name]) do
      cb(...)
    end
  end
end

local function enter_scope(kind, name)
  if jape.scopes:size() == 0 then
    jape.initialize()
  end
  jape.scopes:push({
    kind = kind, 
    name = name,
    callbacks = {before_each = {}, after_each = {}}
  })
end

local function leave_scope(kind, name)
  local top = jape.scopes[-1]
  local curkind = top and top.kind
  if curkind ~= kind then
    log.warn(
      ("Scope mismatch: current is %s, tried to leave %s"):format(
        tostring(curkind, kind)
      )
    )
    return
  end
  jape.scopes:pop()
  if jape.scopes:size() == 0 then
    jape.finalize()
  end
end

local function enter_group(name)
  print("---", name, "---")
  enter_scope("group", name)
  jape.current_group = name
end

local function leave_group()
  jape.current_group = nil
  leave_scope("group")
end

local function enter_test(name)
  enter_scope("test", name)
  jape.current_test = {name = name, count = 0, passed = 0, failed = 0}
  invoke_callbacks("before_each", false)
end

local function leave_test()
  invoke_callbacks("after_each", true)
  local cur = jape.current_test
  local success = cur.passed == cur.count
  if success then
    jape.stats.passed = jape.stats.passed + 1
    print(fmt_cond("OK", cur.name))
  else
    jape.stats.failed = jape.stats.failed + 1
    print(fmt_cond("FAIL", cur.name))
  end
  jape.current_test = nil
  leave_scope("test")
end

local function skip_test(name)
  jape.stats.skipped = jape.stats.skipped + 1
  print(fmt_cond("SKIP", name))
end

local function format_failure(msg, ...)
  local args = {}
  for idx = 1, select('#', ...) do
    args[idx] = deepprint(select(idx, ...))
  end
  return msg:format(unpack(args))
end

local function find_failure_origin()
  for idx = 1, 100 do
    local info = debug.getinfo(idx, "Sl")
    if not info then break end
    if not info.short_src:find("jape.t", 1, true) then
      local source = info.source
      if source:sub(1,1) == "@" then
        source = truss.get_source(info.source:sub(2))
      end
      if source then
        local lines = sutil.split_lines(source)
        source = lines[info.currentline]
      end
      return info.short_src, info.currentline, source or "?"
    end
  end
  return "unknown", 0, ""
end


local function test_result(is_ok, msg, ...)
  local cur = jape.current_test
  if not cur then
    log.warn("No current test!")
    return
  end
  cur.count = cur.count + 1
  local failed = (not is_ok) or (is_ok == "error")
  local fail_trace = nil
  if failed then
    local sourcefile, linenum, sourceline = find_failure_origin()
    fail_trace = sourcefile .. ": " .. linenum .. "> " .. sourceline
  end
  if is_ok == "error" then
    cur.failed = cur.failed + 1
    print("ERROR [" .. cur.name .. "]: " .. msg)
    print("at " .. fail_trace)
  elseif is_ok then
    cur.passed = cur.passed + 1
  else
    cur.failed = cur.failed + 1
    print("FAILED [" .. cur.name .. "]: " .. format_failure(msg, ...))
    print("at " .. fail_trace)
  end
end

local Test = truss.nanoclass("Test")
function Test:init()
end

Test.__call = function(self, name, testfunc)
  enter_test(name)
  local happy, errmsg = pcall(testfunc, jape)
  if not happy then
    --log.error("Test", name, "had errors:", errmsg)
    test_result("error", errmsg)
  end
  leave_test()
end

function Test:skip(name, _testfunc)
  skip_test(name)
end
jape.test = Test:new()

-- hmm: have a 'comparator' type thing?
--[[
compare.exact_equals = {
  check = function(a, b)
    return a == b
  end,
  format = function(a, b)
    -- hmmmmm
  end
}
]]

local matchers = {}

function matchers:to_be(val)
  self:_result(self.value == val, "%s == %s", self.value, val)
end

function matchers:to_equal(val)
  self:_result(deepeq(self.value, val), "deepeq(%s, %s)", self.value, val)
end

function matchers:to_strict_equal(val)
  self:to_equal(val)
end

function matchers:to_be_nil()
  self:to_be(nil)
end

function matchers:to_be_null()
  self:to_be_nil()
end

function matchers:to_be_undefined()
  self:to_be_nil()
end

function matchers:to_be_NaN()
  local isnan = (type(self.value) == 'number') and (self.value ~= self.value)
  self:_result(isnan, "%s is NaN", self.value)
end

function matchers:to_be_defined()
  self:_not():to_be_nil()
end

function matchers:to_be_falsy()
  self:_result(not self.value, "%s is falsy", self.value)
end

function matchers:to_be_truthy()
  self:_result(not not self.value, "%s is truthy", self.value)
end

function matchers:to_contain(val)
  self:_result(contains(self.value, val), "%s contains %s", self.value, val)
end

function matchers:to_throw(expected_error)
  local happy, errmsg = pcall(self.value)
  local msg_ok = true
  if expected_error then
    msg_ok = errmsg and errmsg:find(expected_error)
    msg_ok = not not msg_ok -- coerce to bool
  end
  local throw_msg = ((not happy) and tostring(errmsg)) or "false"
  self:_result((not happy) and msg_ok, "function throws: " .. throw_msg)
end

function matchers:to_have_length(len)
  self:_result(#self.value == len, "len(%s) == %s", self.value, len)
end

function matchers:to_have_property(path, value)
  local propval = get_prop(self.value, path)
  if value then
    self:_result(strict_deepequal(propval, value), "%s has property", self.value)
  else
    self:_result(propval ~= nil, "%s has property", self.value)
  end
end

function matchers:to_be_close(val)
  self:_result(is_close(self.value, val), "%s is close to %s", self.value, val)
end

function matchers:to_be_greater_than(val)
  self:_result(self.value > val, "%s > %s", self.value, val)
end

function matchers:to_be_greater_than_or_equal(val)
  self:_result(self.value >= val, "%s >= %s", self.value, val)
end

function matchers:to_be_less_than(val)
  self:_result(self.value < val, "%s < %s", self.value, val)
end

function matchers:to_be_less_than_or_equal(val)
  self:_result(self.value <= val, "%s <= %s", self.value, val)
end

function matchers:to_be_in_range(min, max)
  self:_result(
    self.value >= min and self.value <= max,
    "%s <= %s <= %s", min, self.value, max
  )
end

local Expectation = truss.nanoclass("Expectation")
Expectation.__index = function(self, k)
  if k == 'not' then
    return Expectation._not(self)
  else
    return Expectation[k]
  end
end

function Expectation:init(val)
  self._class = "Expectation"
  self.value = val
  self.inverted = false
end

local function checkself(self)
  assert(
    type(self) == 'table' and self._class == "Expectation",
    "matchers must be called with : and not . (e.g., expect(foo):toBe(bar))"
  )
end

for name, matcher in pairs(matchers) do
  local mfunc = function(self, ...)
    checkself(self)
    return matcher(self, ...)
  end
  Expectation[name] = mfunc
  Expectation[sutil.camel_case(name)] = mfunc
end

function Expectation:_result(is_ok, msg, ...)
  if self.inverted then
    is_ok = not is_ok
    msg = "not (" .. msg .. ")"
  end
  test_result(is_ok, msg, ...)
end

function Expectation:_not()
  self.inverted = not self.inverted
  return self
end

function jape.expect(val)
  return Expectation:new(val)
end

function jape.describe(groupname, tests)
  enter_group(groupname)
  local happy, errmsg = pcall(tests, jape)
  if not happy then
    log.error("Test group had errors:", groupname, errmsg)
  end
  leave_group()
end

function jape.reset_stats()
  jape.stats = {
    passed = 0, 
    failed = 0, 
    errors = 0, 
    skipped = 0,
    count = 0
  }
end

function jape.initialize()
  log.crit("Initializing Jape!")
  jape.reset_stats()
  log.push_scope()
  log.clear_enabled()
  log.set_enabled({"crit", "fatal", "error", "warn"})
end

function jape.finalize()
  log.crit("Finalizing Jape!")
  print("PASSED: " .. jape.stats.passed)
  print("FAILED: " .. jape.stats.failed + jape.stats.errors)
  print("SKIPPED: " .. jape.stats.skipped)
  log.pop_scope()
end

function jape.run_tests(testlist)
  enter_scope("top")
  for _, test_path in ipairs(testlist) do
    local tests = truss.try_require(test_path)
    if tests then
      -- try to be as generous as possible re: what the entrypoint is named.
      print("=>", test_path)
      (tests.run or tests.main or tests.init)(jape)
    end
  end
  leave_scope("top")
  return (jape.stats.failed == 0) and (jape.stats.errors == 0)
end

function jape.main()
  -- TODO: arg handling?
  local pkginfo = require("dev/pkginfo.t")
  local testlist = {}
  if truss.args[3] then
    local testname = truss.args[3]
    if not truss.fs.file_extension(testname) then
      testname = testname .. "/_tests.t"
    end
    testlist = {testname}
  else
    for _, info in ipairs(pkginfo.list_packages()) do
      local test_path = info.name .. "/_tests.t"
      table.insert(testlist, test_path)
    end
  end
  if not jape.run_tests(testlist) then
    return 1
  end
end

local function cur_scope()
  return assert(jape.scopes[-1], "Not inside a Jape scope!")
end

function jape.before_each(f)
  table.insert(cur_scope().callbacks.before_each, f)
end

function jape.after_each(f)
  table.insert(cur_scope().callbacks.after_each, f)
end

return jape