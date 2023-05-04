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

local function NYI()
  assert(false, "NYI!")
end

local function test_result(is_ok)
  -- TODO
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

local Jape = truss.nanoclass()
function Jape:init()
end

Jape.__call = function(self, name, testfunc)
end

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

local Expectation = truss.nanoclass()
Expectation.__index = function(self, k)
  if k == 'not' then
    return Expectation._not(self)
  else
    return Expectation[k]
  end
end

function Expectation:init(val)
  self.value = val
  self.inverted = false
end

function Expectation:_result(is_ok)
  if self.inverted then
    is_ok = not is_ok
  end
  test_result(is_ok)
end

function Expectation:_not()
  self.inverted = not self.inverted
  return self
end

function Expectation:toBe(val)
  self:_result(self.value == val)
end

function Expectation:toEqual(val)
  self:_result(deepequal(self.value, val))
end

function Expectation:toStrictEqual(val)
  self:toEqual(val)
end

function Expectation:toBeNil()
  self:toBe(nil)
end

function Expectation:toBeNull()
  self:toBeNil()
end

function Expectation:toBeUndefined()
  self:toBeNil()
end

function Expectation:toBeNaN()
  local isnan = (type(self.value) == 'number') and (self.value ~= self.value)
  self:_result(isnan)
end

function Expectation:toBeDefined()
  self.not.toBeUndefined()
end

function Expectation:toBeFalsy()
  self:_result(not self.value)
end

function Expectation:toBeTruthy()
  self:_result(not not self.value)
end

function Expectation:toContain(val)
  self:_result(contains(self.value, val))
end

function Expectation:toThrow(expected_error)
  local happy, errmsg = pcall(self.value)
  local msg_ok = true
  if expected_error then
    msg_ok = errmsg and errmsg:find(expected_error)
    msg_ok = not not msg_ok -- coerce to bool
  end
  self:_result((not happy) and msg_ok)
end

function Expectation:toHaveLength(len)
  self:_result(#self.value == len)
end

function Expectation:toHaveProperty(path, value)
  local propval = get_prop(self.value, path)
  if value then
    self:_result(strict_deepequal(propval, value))
  else
    self:_result(propval ~= nil)
  end
end

function Expectatino:toBeCloseTo(val)
  self:_result(is_close(self.value, val))
end

function Expectation:toBeGreaterThan(val)
  self:_result(self.value > val)
end

function Expectation:toBeGreaterThanOrEqual(val)
  self:_result(self.value >= val)
end

function Expectation:toBeLessThan(val)
  self:_result(self.value < val)
end

function Expectation:toBeLessThanOrEqual(val)
  self:_result(self.value <= val)
end


local function expect(val)
  return Expectation:new(val)
end

local function describe(groupname, tests)

end

local function init_tests()
end

local function update_tests()
  -- todo?
  truss.quit()
end

return {
  Jape = Jape,
  describe = describe,
  expect = expect,
  test = Jape:new(),
  init = init_tests,
  update = update_tests
}