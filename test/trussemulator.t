-- trussemulator.t
--
-- emulates truss functions like truss_import(...) so that truss modules can be tested
-- using the terra binary

local m = {}

-- wraps a truss_import around an importpath
function m.makeImport(importPath)
	local p = importPath

	local function ret(fn)
		local truepath = importPath .. fn
		local f, err = terralib.loadfile(truepath)
		if err then 
			print(err) 
		else 
			return f() 
		end
	end

	return ret
end

-- makes a fake trss library
function m.makeTRSS()
	return m
end

return m