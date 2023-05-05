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
jape.pre_funcs = {}
jape.post_funcs = {}

local function enter_group(name)
  jape.current_group = name
end

local function leave_group()
  jape.current_group = nil
  jape.pre_funcs = {}
  jape.post_funcs = {}
end

local function enter_test(name)
  jape.current_test = {name = name, count = 0, successes = 0, failures = 0, errors = 0}
  for _, func in ipairs(jape.pre_funcs) do
    func()
  end
end

local function leave_test()
  for _, func in ipairs(jape.post_funcs) do
    func()
  end
  local cur = jape.current_test
  local success = cur.successes == cur.count
  if success then
    print(cur.name, "[OK]")
  else
    print(cur.name, "[FAIL]")
  end
  jape.current_test = nil
end

local function skip_test(name)
end

local function format_failure(msg, ...)
  local args = {}
  for idx = 1, select('#', ...) do
    args[idx] = deepprint(select(idx, ...))
  end
  return msg:format(unpack(args))
end

local function test_result(is_ok, msg, ...)
  local cur = assert(jape.current_test, "no current test?")
  cur.count = cur.count + 1
  if is_ok then
    cur.successes = cur.successes + 1
  else
    cur.failures = cur.failures + 1
    print("FAILED [" .. cur.name .. "]: " .. format_failure(msg, ...))
  end
end

local Test = truss.nanoclass()
function Test:init()
end

Test.__call = function(self, name, testfunc)
  enter_test(name)
  local happy, errmsg = pcall(testfunc, jape)
  if not happy then
    log.error("Test", name, "had errors:", errmsg)
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
  self:_result(deepequal(self.value, val), "deepeq(%s, %s)", self.value, val)
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
  self:_result((not happy) and msg_ok, "function throws")
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

local Expectation = truss.nanoclass()
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

function jape.init()
  -- TODO: arg handling?
  local pkginfo = require("dev/pkginfo.t")
  for _, info in ipairs(pkginfo.list_packages()) do
    local test_path = info.name .. "/" .. "_tests.t"
    local tests = truss.try_require(test_path)
    if tests then
      log.info("Running tests for", info.name)
      (tests.run or tests.init)(jape)
    else
      log.info("No tests for", info.name)
    end
  end
end

function jape.before_each(f)
  table.insert(jape.pre_funcs, f)
end

function jape.after_each(f)
  table.insert(jape.post_funcs, f)
end

function jape.update()
  -- todo?
  truss.quit()
end

return jape