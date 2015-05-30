-- trussemulator.t
--
-- emulates truss functions like truss_import(...) so that truss modules can be tested
-- using the terra binary

local m = {}

-- wraps a truss_import around an importpath
function m.makeImport(importPath)
	local p = importPath

	local loaded_ = {}
	local function ret(fn)
		if loaded_[fn] == nil then
			loaded_[fn] = {} -- avoid infinite loops

			local truepath = importPath .. fn
			local f, err = terralib.loadfile(truepath)
			if err then 
				print(err)
				loaded_[fn] = nil
			else 
				loaded_[fn] = f()
			end
		end

		return loaded_[fn]
	end

	return ret
end

function m.trss_log(loglevel, msg)
	print(loglevel .. "| " .. msg)
end

-- makes a fake trss library
function m.makeTRSS()
	return m
end

return m