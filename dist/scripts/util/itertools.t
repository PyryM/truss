-- itertools.t
--
-- some useful tools for iterating through things

local itertools = {}

function itertools.iterate(target)
    if target.iteritems then
        return target:iteritems()
    else
        return pairs(target)
    end
end

return itertools