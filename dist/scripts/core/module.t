-- core/module.t
--
-- contains a bunch of useful functions for creating modules

local m = {}

function m.reexport(srcname, destmodule)
    local srcmodule = require(srcname)
    if not srcmodule then
        return
    end
    local src = srcmodule.exports or srcmodule
    for k,v in pairs(src) do
        if not destmodule[k] then
            destmodule[k] = v
        else
            log.error("Rexport: destination already has " .. k)
        end
    end
end

function m.includeSubmodules(srclist, dest)
    for _,srcname in ipairs(srclist) do
        m.reexport(srcname, dest)
    end
end

return m
