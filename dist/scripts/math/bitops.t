-- bitwise operations on 64 bit integers
-- (luajit's bit module operates on lua ~52 bit ints)

local m = {}

terra m.ulland(a: uint64, b: uint64) : uint64
    return a and b
end

terra m.ullor(a: uint64, b: uint64) : uint64
    return a or b
end

terra m.ullnot(a: uint64) : uint64
    return not a
end

terra m.ullxor(a: uint64, b: uint64) : uint64
    return a ^ b
end

terra m.ulllshift(a: uint64, b: int32) : uint64
    return a << b
end

terra m.ullrshift(a: uint64, b: int32) : uint64
    return a >> b
end

function m.combineFlags(...)
    local args = {...}
    local v = args[1]
    for i = 2,#args do
        v = m.ullor(v, args[i])
    end
    return v
end

return m
