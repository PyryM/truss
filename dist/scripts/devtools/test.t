-- devtools/test.t
--
-- largely adapted from 'gambiarra':
-- https://bitbucket.org/zserge/gambiarra
-- (MIT license)

local m = {}

local function TERMINAL_HANDLER(e, test, msg)
	if e == 'pass' then
		print("[32mâœ”[0m "..test..': '..msg)
	elseif e == 'fail' then
		print("[31mâœ˜[0m "..test..': '..msg)
	elseif e == 'except' then
		print("[31mâœ˜[0m "..test..': '..msg)
	end
end

local function deepeq(a, b)
	-- Different types: false
	if type(a) ~= type(b) then return false end
	-- Functions
	if type(a) == 'function' then
		return string.dump(a) == string.dump(b)
	end
	-- Primitives and equal pointers
	if a == b then return true end
	-- Only equal tables could have passed previous tests
	if type(a) ~= 'table' then return false end
	-- Compare tables field by field
	for k,v in pairs(a) do
		if b[k] == nil or not deepeq(v, b[k]) then return false end
	end
	for k,v in pairs(b) do
		if a[k] == nil or not deepeq(v, a[k]) then return false end
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

local pendingtests = {}
local gambiarrahandler = TERMINAL_HANDLER

function m.set_handler(handler)
	gambiarrahandler = handler
end

local function runpending()
	if pendingtests[1] ~= nil then pendingtests[1](runpending) end
end

function m.test(name, f, async)
	local testfn = function(next)
		local finish_test = function()
			gambiarrahandler('end', name)
			table.remove(pendingtests, 1)
			if next then next() end
		end

		local handler = gambiarrahandler

		local funcs = {}
		funcs.eq = deepeq
		funcs.spy = spy
		funcs.ok = function(cond, msg)
			if not msg then
				msg = debug.getinfo(2, 'S').short_src .. ":"
					 .. debug.getinfo(2, 'l').currentline
			end
			if cond then
				handler('pass', name, msg)
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

return m
